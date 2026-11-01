#!/usr/bin/env bun

import { createHash, randomBytes } from 'node:crypto';
import { spawn } from 'node:child_process';
import { type Stats } from 'node:fs';
import {
  type FileHandle,
  mkdir,
  open,
  readFile,
  readdir,
  rename,
  stat,
  unlink,
} from 'node:fs/promises';
import { homedir } from 'node:os';
import { basename, dirname, isAbsolute, join } from 'node:path';
import { TextDecoder } from 'node:util';

const MANIFEST_SCHEMA = 'note-overlay-review/v1';
const DEFAULT_OUTPUT = '~/Documents/vault/.note-overlay';
const DEFAULT_REMOTE = 'remote:Documents/raw';
const UTF8_DECODER = new TextDecoder('utf-8', { fatal: true });

type JsonObject = Record<string, unknown>;
type Point = [number, number, number];

interface Backup {
  readonly filename: string;
  readonly sha256: string;
  readonly books: Array<unknown>;
}

interface SelectedBook {
  readonly book: JsonObject;
  readonly backup: Backup;
  readonly bookId: string;
}

interface Stroke {
  readonly index: number;
  readonly kind: number;
  readonly width: number;
  readonly started_ms: number;
  readonly duration_ms: number;
  readonly points: Array<Point>;
}

interface ImageBounds {
  readonly x: number;
  readonly y: number;
  readonly w: number;
  readonly h: number;
}

interface ImageSource {
  readonly package: string | null;
  readonly title: string | null;
  readonly url: string | null;
}

interface DecodedImage {
  readonly index: number;
  readonly bounds: ImageBounds;
  readonly sha256: string;
  readonly source: ImageSource;
  readonly data: Buffer;
  asset: string;
}

interface DecodedPage {
  readonly id: string;
  readonly strokes: Array<Stroke>;
  readonly images: Array<DecodedImage>;
}

interface RenderedPage {
  readonly reviewSvg: string;
  readonly artifacts: Array<string>;
  readonly changed: Array<string>;
}

interface Options {
  readonly inputs: Array<string>;
  readonly isDrive: boolean;
  readonly remote: string;
  readonly rclone: string;
  readonly output: string;
  readonly width: number;
  readonly height: number;
}

interface Source {
  readonly type: 'drive' | 'local';
  readonly remote?: string;
}

class ExtractError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = 'ExtractError';
  }
}

class RcloneError extends Error {
  readonly exitCode: number;

  constructor(exitCode: number) {
    super(`rclone exited ${exitCode}`);
    this.name = 'RcloneError';
    this.exitCode = exitCode;
  }
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function requireObject(value: unknown, where: string): JsonObject {
  if (!isObject(value)) {
    throw new ExtractError(`${where} must be an object`);
  }
  return value;
}

function requireNumber(value: unknown, where: string): number {
  if (typeof value !== 'number') {
    throw new ExtractError(`${where} must be a number`);
  }
  if (!Number.isFinite(value)) {
    throw new ExtractError(`${where} must be finite`);
  }
  return value;
}

function requireText(value: unknown, where: string): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw new ExtractError(`${where} must be a non-empty string`);
  }
  return value;
}

function optionalText(value: unknown, where: string): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (typeof value !== 'string') {
    throw new ExtractError(`${where} must be a string or null`);
  }
  return value;
}

function requireList(value: unknown, where: string): Array<unknown> {
  if (!Array.isArray(value)) {
    throw new ExtractError(`${where} must be a list`);
  }
  return value;
}

function defaultList(value: unknown): unknown {
  return value === undefined ? [] : value;
}

function nullableProperty(record: JsonObject, key: string): unknown {
  return record[key] === undefined ? null : record[key];
}

function sha256(data: Uint8Array): string {
  return createHash('sha256').update(data).digest('hex');
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(canonicalize);
  }
  if (!isObject(value)) {
    return value;
  }
  const sorted: JsonObject = {};
  for (const key of Object.keys(value).sort()) {
    sorted[key] = canonicalize(value[key]);
  }
  return sorted;
}

function canonicalJson(value: unknown): string {
  const encoded = JSON.stringify(canonicalize(value));
  if (encoded === undefined) {
    throw new ExtractError('content cannot be represented as JSON');
  }
  return encoded;
}

function contentHash(value: unknown): string {
  return createHash('sha256').update(canonicalJson(value), 'utf8').digest('hex');
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

async function loadBackup(path: string): Promise<Backup> {
  let raw: Buffer;
  let document: unknown;
  try {
    raw = await readFile(path);
    document = JSON.parse(UTF8_DECODER.decode(raw));
  } catch (error) {
    throw new ExtractError(`cannot read ${path}: ${errorMessage(error)}`, { cause: error });
  }
  const root = requireObject(document, `${path}: backup root`);
  if (root.app !== 'note-overlay' || root.v !== 2) {
    throw new ExtractError(`${path}: expected a note-overlay v2 backup`);
  }
  const books = requireList(root.books, `${path}: books`);
  return { filename: basename(path), sha256: sha256(raw), books };
}

async function collectInputs(inputs: Array<string>): Promise<Array<string>> {
  const paths: Array<string> = [];
  for (const input of inputs) {
    let information: Stats;
    try {
      information = await stat(input);
    } catch (error) {
      throw new ExtractError(`input does not exist: ${input}`, { cause: error });
    }
    if (information.isDirectory()) {
      const entries = await readdir(input);
      for (const entry of entries.filter((name) => name.endsWith('.json')).sort()) {
        paths.push(join(input, entry));
      }
    } else if (information.isFile()) {
      paths.push(input);
    } else {
      throw new ExtractError(`input does not exist: ${input}`);
    }
  }
  if (paths.length === 0) {
    throw new ExtractError('no JSON backups found');
  }
  return paths;
}

function compareText(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}

async function loadBackups(paths: Array<string>): Promise<Array<Backup>> {
  const orderedPaths = [...paths].sort((left, right) => {
    const filenameOrder = compareText(basename(left), basename(right));
    return filenameOrder === 0 ? compareText(left, right) : filenameOrder;
  });
  const backups = new Map<string, Backup>();
  for (const path of orderedPaths) {
    const backup = await loadBackup(path);
    const previous = backups.get(backup.filename);
    if (previous !== undefined) {
      if (previous.sha256 !== backup.sha256) {
        throw new ExtractError(`ambiguous backups share filename '${backup.filename}'`);
      }
      continue;
    }
    backups.set(backup.filename, backup);
  }
  return [...backups.values()].sort((left, right) =>
    compareText(left.filename, right.filename),
  );
}

function selectLatestBooks(backups: Array<Backup>): Array<SelectedBook> {
  interface RankedBook extends SelectedBook {
    readonly modified: number;
  }
  const selected = new Map<string, RankedBook>();
  for (const backup of backups) {
    for (const [index, value] of backup.books.entries()) {
      const where = `${backup.filename}: books[${index}]`;
      const book = requireObject(value, where);
      const bookId = requireText(book.id, `${where}.id`);
      const modified = requireNumber(book.m, `${where}.m`);
      const current = selected.get(bookId);
      const isLater = current === undefined ||
        modified > current.modified ||
        (modified === current.modified && backup.filename > current.backup.filename);
      if (isLater) {
        selected.set(bookId, { book, backup, bookId, modified });
      }
    }
  }
  return [...selected.values()]
    .sort((left, right) => compareText(left.bookId, right.bookId))
    .map(({ book, backup, bookId }) => ({ book, backup, bookId }));
}

function decodeWebp(value: unknown, where: string): Buffer {
  let encoded = requireText(value, where);
  if (encoded.startsWith('data:')) {
    const marker = ';base64,';
    const markerIndex = encoded.indexOf(marker);
    if (markerIndex < 0) {
      throw new ExtractError(`${where} data URL must be Base64`);
    }
    encoded = encoded.slice(markerIndex + marker.length);
  }
  const base64Pattern = /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;
  if (!base64Pattern.test(encoded)) {
    throw new ExtractError(`${where} is not valid Base64`);
  }
  const data = Buffer.from(encoded, 'base64');
  if (data.length < 12 || data.subarray(0, 4).toString('ascii') !== 'RIFF' ||
      data.subarray(8, 12).toString('ascii') !== 'WEBP') {
    throw new ExtractError(`${where} does not contain a WebP image`);
  }
  return data;
}

function decodePoints(packed: Array<unknown>, where: string): Array<Point> {
  if (packed.length === 0 || packed.length % 3 !== 0) {
    throw new ExtractError(`${where} must contain x/y/pressure triples`);
  }
  const points: Array<Point> = [];
  for (let offset = 0; offset < packed.length; offset += 3) {
    points.push([
      requireNumber(packed[offset], `${where}[${offset}]`),
      requireNumber(packed[offset + 1], `${where}[${offset + 1}]`),
      requireNumber(packed[offset + 2], `${where}[${offset + 2}]`),
    ]);
  }
  return points;
}

function decodeStroke(value: unknown, where: string, index: number): Stroke {
  const stroke = requireObject(value, where);
  const packed = requireList(stroke.p, `${where}.p`);
  const width = requireNumber(stroke.w, `${where}.w`);
  const duration = requireNumber(stroke.dur, `${where}.dur`);
  if (width <= 0 || duration < 0) {
    throw new ExtractError(`${where} has invalid width or duration`);
  }
  const kind = stroke.k === undefined ? 0 : stroke.k;
  if (typeof kind !== 'number' || !Number.isInteger(kind)) {
    throw new ExtractError(`${where}.k must be an integer`);
  }
  return {
    index,
    kind,
    width,
    started_ms: requireNumber(stroke.t0, `${where}.t0`),
    duration_ms: duration,
    points: decodePoints(packed, `${where}.p`),
  };
}

function decodeImage(value: unknown, where: string, index: number): DecodedImage {
  const image = requireObject(value, where);
  const bounds = {
    x: requireNumber(image.x, `${where}.x`),
    y: requireNumber(image.y, `${where}.y`),
    w: requireNumber(image.w, `${where}.w`),
    h: requireNumber(image.h, `${where}.h`),
  };
  if (bounds.w <= 0 || bounds.h <= 0) {
    throw new ExtractError(`${where} has invalid dimensions`);
  }
  const data = decodeWebp(image.data, `${where}.data`);
  return {
    index,
    bounds,
    sha256: sha256(data),
    source: {
      package: optionalText(image.sp, `${where}.sp`),
      title: optionalText(image.st, `${where}.st`),
      url: optionalText(image.su, `${where}.su`),
    },
    data,
    asset: '',
  };
}

function decodePage(value: unknown, where: string): DecodedPage {
  const page = requireObject(value, where);
  const id = requireText(page.id, `${where}.id`);
  const strokes = requireList(defaultList(page.s), `${where}.s`).map((stroke, index) =>
    decodeStroke(stroke, `${where}.s[${index}]`, index),
  );
  const images = requireList(defaultList(page.i), `${where}.i`).map((image, index) =>
    decodeImage(image, `${where}.i[${index}]`, index),
  );
  return { id, strokes, images };
}

function formatNumber(value: number): string {
  const fixed = value.toFixed(6);
  const formatted = fixed.replace(/0+$/, '').replace(/\.$/, '');
  return formatted === '' || formatted === '-0' && value === 0 && !Object.is(value, -0)
    ? '0'
    : formatted;
}

async function isFile(path: string): Promise<boolean> {
  try {
    return (await stat(path)).isFile();
  } catch (error) {
    if (isObject(error) && error.code === 'ENOENT') {
      return false;
    }
    throw error;
  }
}

async function writeIfChanged(path: string, data: Uint8Array): Promise<boolean> {
  if (await isFile(path) && Buffer.compare(await readFile(path), data) === 0) {
    return false;
  }
  const directory = dirname(path);
  await mkdir(directory, { recursive: true });
  const temporary = join(
    directory,
    `.${basename(path)}.${process.pid}.${randomBytes(8).toString('hex')}`,
  );
  let handle: FileHandle | undefined;
  let ownsTemporary = false;
  try {
    handle = await open(temporary, 'wx', 0o600);
    ownsTemporary = true;
    await handle.writeFile(data);
    await handle.close();
    await rename(temporary, path);
    ownsTemporary = false;
  } finally {
    if (handle !== undefined) {
      await handle.close().catch(() => undefined);
    }
    if (ownsTemporary && await isFile(temporary)) {
      await unlink(temporary);
    }
  }
  return true;
}

function xmlEscape(value: string): string {
  return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function publicImage(image: DecodedImage): JsonObject {
  return {
    index: image.index,
    bounds: image.bounds,
    sha256: image.sha256,
    source: image.source,
    asset: image.asset,
  };
}

function renderImageElement(image: DecodedImage, width: number, height: number): string {
  const bounds = image.bounds;
  const href = `assets/${basename(image.asset)}`;
  return '  <image' +
    ` x="${formatNumber(bounds.x * width)}"` +
    ` y="${formatNumber(bounds.y * height)}"` +
    ` width="${formatNumber(bounds.w * width)}"` +
    ` height="${formatNumber(bounds.h * height)}"` +
    ` href="${href}" preserveAspectRatio="none"/>`;
}

function renderStrokeElement(stroke: Stroke, width: number, height: number): string {
  const pathData = stroke.points.map((point, index) =>
    `${index === 0 ? 'M' : 'L'}${formatNumber(point[0] * width)} ${formatNumber(point[1] * height)}`,
  ).join(' ');
  return '  <path' +
    ` d="${pathData}"` +
    ' fill="none" stroke="#111111" stroke-linecap="round"' +
    ' stroke-linejoin="round"' +
    ` stroke-width="${formatNumber(stroke.width * width)}"` +
    ` data-kind="${stroke.kind}"` +
    ` data-started-ms="${stroke.started_ms}"` +
    ` data-duration-ms="${stroke.duration_ms}"/>`;
}

async function renderPage(
  output: string,
  bookId: string,
  page: DecodedPage,
  width: number,
  height: number,
): Promise<RenderedPage> {
  const relativeDirectory = join('review', bookId);
  const changed: Array<string> = [];
  const artifacts: Array<string> = [];
  for (const image of page.images) {
    const filename = `${page.id}-${image.index.toString().padStart(2, '0')}-${image.sha256.slice(0, 16)}.webp`;
    const relativeAsset = join(relativeDirectory, 'assets', filename);
    artifacts.push(relativeAsset);
    if (await writeIfChanged(join(output, relativeAsset), image.data)) {
      changed.push(relativeAsset);
    }
    image.asset = relativeAsset;
  }
  const metadata = xmlEscape(`note-overlay review: notebook=${bookId}; page=${page.id}`);
  const elements = page.images.map((image) => renderImageElement(image, width, height));
  elements.push(...page.strokes.map((stroke) => renderStrokeElement(stroke, width, height)));
  const svg = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" data-note-overlay-review="true">`,
    `  <metadata>${metadata}</metadata>`,
    `  <rect width="${width}" height="${height}" fill="white"/>`,
    ...elements,
    '</svg>',
    '',
  ].join('\n');
  const relativeSvg = join(relativeDirectory, `${page.id}.svg`);
  artifacts.push(relativeSvg);
  if (await writeIfChanged(join(output, relativeSvg), Buffer.from(svg, 'utf8'))) {
    changed.push(relativeSvg);
  }
  return { reviewSvg: relativeSvg, artifacts, changed };
}

async function previousArtifacts(path: string): Promise<Set<string>> {
  if (!await isFile(path)) {
    return new Set();
  }
  try {
    const manifest: unknown = JSON.parse(UTF8_DECODER.decode(await readFile(path)));
    if (!isObject(manifest) || !Array.isArray(manifest.artifacts)) {
      return new Set();
    }
    return new Set(manifest.artifacts.filter((item): item is string => typeof item === 'string'));
  } catch {
    return new Set();
  }
}

function assertSafeArtifact(relative: string): void {
  const parts = relative.split('/');
  if (isAbsolute(relative) || parts.includes('..') || parts[0] !== 'review') {
    throw new ExtractError(`unsafe artifact path in previous manifest: ${relative}`);
  }
}

async function removeStaleArtifacts(output: string, stale: Set<string>): Promise<Array<string>> {
  const removed: Array<string> = [];
  for (const relative of [...stale].sort()) {
    assertSafeArtifact(relative);
    const target = join(output, relative);
    if (await isFile(target)) {
      await unlink(target);
      removed.push(relative);
    }
  }
  return removed;
}

async function extract(
  backups: Array<Backup>,
  output: string,
  source: Source,
  width: number,
  height: number,
): Promise<[number, number, number]> {
  const manifestPath = join(output, 'manifest.json');
  const oldArtifacts = await previousArtifacts(manifestPath);
  const currentArtifacts = new Set<string>();
  const changed: Array<string> = [];
  const notebooks: Array<JsonObject> = [];
  for (const { book, backup, bookId } of selectLatestBooks(backups)) {
    const pages = requireList(book.pages, `notebook ${bookId}: pages`);
    const pageRecords: Array<JsonObject> = [];
    const seenPages = new Set<string>();
    for (const [pageIndex, rawPage] of pages.entries()) {
      const page = decodePage(rawPage, `notebook ${bookId}: pages[${pageIndex}]`);
      if (seenPages.has(page.id)) {
        throw new ExtractError(`duplicate page ID ${page.id} in notebook ${bookId}`);
      }
      seenPages.add(page.id);
      const rendered = await renderPage(output, bookId, page, width, height);
      for (const artifact of rendered.artifacts) currentArtifacts.add(artifact);
      changed.push(...rendered.changed);
      pageRecords.push({
        id: page.id,
        index: pageIndex,
        zettel_id: `note-overlay-${page.id}`,
        content_sha256: contentHash(rawPage),
        review_svg: rendered.reviewSvg,
        strokes: page.strokes,
        images: page.images.map(publicImage),
      });
    }
    notebooks.push({
      id: bookId,
      title: optionalText(book.n, `notebook ${bookId}.n`),
      created_ms: nullableProperty(book, 'c'),
      modified_ms: book.m,
      notebook_type: nullableProperty(book, 't'),
      order: nullableProperty(book, 'o'),
      content_sha256: contentHash(book),
      source_backup: { filename: backup.filename, sha256: backup.sha256 },
      pages: pageRecords,
    });
  }
  const manifest = {
    schema: MANIFEST_SCHEMA,
    source,
    canvas: { width, height, units: 'px' },
    backups: backups.map((backup) => ({ filename: backup.filename, sha256: backup.sha256 })),
    artifacts: [...currentArtifacts].sort(),
    notebooks,
  };
  const stale = new Set([...oldArtifacts].filter((item) => !currentArtifacts.has(item)));
  const removed = await removeStaleArtifacts(output, stale);
  const manifestBytes = Buffer.from(`${JSON.stringify(canonicalize(manifest), null, 2)}\n`, 'utf8');
  if (await writeIfChanged(manifestPath, manifestBytes)) changed.push('manifest.json');
  return [changed.length, currentArtifacts.size + 1 - changed.length, removed.length];
}

function expandPath(value: string): string {
  if (value === '~') return homedir();
  if (value.startsWith('~/')) return join(homedir(), value.slice(2));
  return value;
}

function positiveDimension(value: string, flag: string): number {
  if (!/^[+-]?\d+$/.test(value.trim())) {
    throw new ExtractError(`${flag}: must be an integer`);
  }
  const dimension = Number(value);
  if (!Number.isSafeInteger(dimension) || dimension <= 0) {
    throw new ExtractError(`${flag}: must be positive`);
  }
  return dimension;
}

function usage(): string {
  return 'Usage: bun extract_note_overlay.ts [--drive] [--output DIRECTORY] ' +
    '[--width PIXELS] [--height PIXELS] [BACKUP ...]';
}

function optionValue(args: Array<string>, index: number, flag: string): string {
  const value = args[index + 1];
  if (value === undefined) {
    throw new ExtractError(`${flag} requires a value`);
  }
  return value;
}

function parseOptions(args: Array<string>): Options | null {
  const inputs: Array<string> = [];
  let isDrive = false;
  let remote = DEFAULT_REMOTE;
  let rclone = 'rclone-drive';
  let output = expandPath(DEFAULT_OUTPUT);
  let width = 1000;
  let height = 1414;
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === '--help' || argument === '-h') {
      console.log(usage());
      return null;
    }
    if (argument === '--drive') {
      isDrive = true;
    } else if (argument === '--output' || argument === '--width' || argument === '--height' ||
        argument === '--remote' || argument === '--rclone') {
      const value = optionValue(args, index, argument);
      index += 1;
      if (argument === '--output') output = expandPath(value);
      if (argument === '--width') width = positiveDimension(value, argument);
      if (argument === '--height') height = positiveDimension(value, argument);
      if (argument === '--remote') remote = value;
      if (argument === '--rclone') rclone = value;
    } else if (argument?.startsWith('-')) {
      throw new ExtractError(`unrecognized argument: ${argument}`);
    } else if (argument !== undefined) {
      inputs.push(expandPath(argument));
    }
  }
  if (isDrive && inputs.length > 0) {
    throw new ExtractError('use either --drive or explicit BACKUP inputs, not both');
  }
  if (!isDrive && inputs.length === 0) {
    throw new ExtractError('supply --drive or at least one BACKUP input');
  }
  return { inputs, isDrive, remote, rclone, output, width, height };
}

async function copyDrive(options: Options): Promise<void> {
  const mirror = join(options.output, 'raw');
  await mkdir(mirror, { recursive: true });
  const args = [
    'copy', options.remote, mirror,
    '--filter', '+ note-overlay-backup-*.json',
    '--filter', '- *',
    '--immutable',
  ];
  const { promise, resolve: resolveExit, reject } = Promise.withResolvers<number>();
  const child = spawn(options.rclone, args, { stdio: 'inherit' });
  child.once('error', reject);
  child.once('exit', (code) => resolveExit(code ?? 1));
  const exitCode = await promise;
  if (exitCode !== 0) throw new RcloneError(exitCode);
}

async function main(): Promise<void> {
  const options = parseOptions(process.argv.slice(2));
  if (options === null) return;
  let inputs = options.inputs;
  let source: Source = { type: 'local' };
  if (options.isDrive) {
    await copyDrive(options);
    inputs = [join(options.output, 'raw')];
    source = { type: 'drive', remote: options.remote };
  }
  const backups = await loadBackups(await collectInputs(inputs));
  const [changed, unchanged, removed] = await extract(
    backups, options.output, source, options.width, options.height,
  );
  console.log(
    `Wrote ${changed} changed artifacts; ${unchanged} unchanged; ` +
    `removed ${removed} stale. Manifest: ${join(options.output, 'manifest.json')}`,
  );
}

try {
  await main();
} catch (error) {
  console.error(`extract_note_overlay: ${errorMessage(error)}`);
  process.exitCode = 1;
}
