#!/usr/bin/env bun

import { spawn } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import { type Stats } from 'node:fs';
import {
  type FileHandle,
  mkdir,
  mkdtemp,
  open,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  unlink,
} from 'node:fs/promises';
import { homedir, tmpdir } from 'node:os';
import { basename, dirname, isAbsolute, join, resolve, sep } from 'node:path';
import { TextDecoder } from 'node:util';

const MANIFEST_SCHEMA = 'note-overlay-review/v2';
const DEFAULT_OUTPUT = '~/Documents/vault/.note-overlay';
const DEFAULT_REMOTE = 'remote:Note Overlay';
const MAX_PAGES = 10_000;
const MAX_COMMAND_OUTPUT = 16 * 1024 * 1024;
const COMMAND_TIMEOUT_MS = 120_000;
const UTF8_DECODER = new TextDecoder('utf-8', { fatal: true });

type JsonObject = Record<string, unknown>;

interface Options {
  readonly inputs: Array<string>;
  readonly isDrive: boolean;
  readonly remote: string;
  readonly rclone: string;
  readonly output: string;
  readonly dpi: number;
}

interface SourceDocument {
  readonly id: string;
  readonly path: string;
  readonly title: string;
  readonly size: number;
  readonly modTime: string;
  readonly rawPath: string;
  readonly expectedSha256: string | null;
}

interface PageDimensions {
  readonly width: number;
  readonly height: number;
}

interface PdfDescription {
  readonly pageCount: number;
  readonly dimensions: Array<PageDimensions>;
}

interface PreviousPage {
  readonly id: string;
  readonly number: number;
  readonly zettelId: string;
  readonly contentSha256: string;
  readonly reviewSha256: string;
  readonly dimensions: PageDimensions;
  readonly reviewPath: string;
  readonly transcriptionPath: string;
}

interface PreviousDocument {
  readonly id: string;
  readonly sha256: string;
  readonly pages: Array<PreviousPage>;
}

interface PreviousManifest {
  readonly documents: Array<PreviousDocument>;
  readonly artifacts: Set<string>;
}

class ExtractError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = 'ExtractError';
  }
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function requireObject(value: unknown, where: string): JsonObject {
  if (!isObject(value)) throw new ExtractError(`${where} must be an object`);
  return value;
}

function requireList(value: unknown, where: string): Array<unknown> {
  if (!Array.isArray(value)) throw new ExtractError(`${where} must be a list`);
  return value;
}

function requireText(value: unknown, where: string): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw new ExtractError(`${where} must be a non-empty string`);
  }
  return value;
}

function requireNumber(value: unknown, where: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new ExtractError(`${where} must be a finite number`);
  }
  return value;
}

function requireInteger(value: unknown, where: string): number {
  const number = requireNumber(value, where);
  if (!Number.isSafeInteger(number)) throw new ExtractError(`${where} must be an integer`);
  return number;
}

function requireSha256(value: unknown, where: string): string {
  const hash = requireText(value, where);
  if (!/^[0-9a-f]{64}$/.test(hash)) throw new ExtractError(`${where} must be a SHA-256 hash`);
  return hash;
}

function sha256(data: Uint8Array): string {
  return createHash('sha256').update(data).digest('hex');
}

async function fileSha256(path: string): Promise<string> {
  return sha256(await readFile(path));
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function compareText(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (!isObject(value)) return value;
  const sorted: JsonObject = {};
  for (const key of Object.keys(value).sort()) sorted[key] = canonicalize(value[key]);
  return sorted;
}

function safeRelativePath(value: unknown, where: string): string {
  const path = requireText(value, where);
  const parts = path.split('/');
  if (isAbsolute(path) || path.includes('\\') || path.includes('\0') ||
      parts.some((part) => part === '' || part === '.' || part === '..')) {
    throw new ExtractError(`${where} is not a safe relative path`);
  }
  return path;
}

function safeDocumentId(value: unknown, where: string): string {
  const id = requireText(value, where);
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,255}$/.test(id) || id === '.' || id === '..') {
    throw new ExtractError(`${where} is not a safe document ID`);
  }
  return id;
}

function pageName(number: number): string {
  return number.toString().padStart(3, '0');
}

async function isFile(path: string): Promise<boolean> {
  try {
    return (await stat(path)).isFile();
  } catch (error) {
    if (isObject(error) && error.code === 'ENOENT') return false;
    throw error;
  }
}

async function writeIfChanged(path: string, data: Uint8Array): Promise<boolean> {
  if (await isFile(path) && Buffer.compare(await readFile(path), data) === 0) return false;
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
    if (handle !== undefined) await handle.close().catch(() => undefined);
    if (ownsTemporary && await isFile(temporary)) await unlink(temporary);
  }
  return true;
}

async function run(command: string, args: Array<string>): Promise<string> {
  const { promise, resolve: settle, reject } = Promise.withResolvers<number>();
  const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'] });
  const stdout: Array<Buffer> = [];
  const stderr: Array<Buffer> = [];
  let stdoutSize = 0;
  let stderrSize = 0;
  let outputExceeded = false;
  let didTimeout = false;
  const timeout = setTimeout(() => {
    didTimeout = true;
    child.kill('SIGKILL');
  }, COMMAND_TIMEOUT_MS);
  child.stdout.on('data', (chunk: Buffer) => {
    stdoutSize += chunk.length;
    if (stdoutSize <= MAX_COMMAND_OUTPUT) stdout.push(chunk);
    else outputExceeded = true;
  });
  child.stderr.on('data', (chunk: Buffer) => {
    stderrSize += chunk.length;
    if (stderrSize <= MAX_COMMAND_OUTPUT) stderr.push(chunk);
    else outputExceeded = true;
  });
  child.once('error', (error) => reject(new ExtractError(`cannot run ${command}: ${errorMessage(error)}`)));
  child.once('exit', (code) => settle(code ?? 1));
  const exitCode = await promise.finally(() => clearTimeout(timeout));
  const errorOutput = Buffer.concat(stderr).toString('utf8').trim();
  if (didTimeout) {
    throw new ExtractError(`${command} timed out after ${COMMAND_TIMEOUT_MS}ms`);
  }
  if (outputExceeded) throw new ExtractError(`${command} produced too much output`);
  if (exitCode !== 0) {
    const detail = errorOutput.length === 0 ? '' : `: ${errorOutput}`;
    throw new ExtractError(`${command} exited ${exitCode}${detail}`);
  }
  return Buffer.concat(stdout).toString('utf8');
}

function expandPath(value: string): string {
  if (value === '~') return homedir();
  if (value.startsWith('~/')) return join(homedir(), value.slice(2));
  return value;
}

function positiveInteger(value: string, flag: string): number {
  if (!/^\d+$/.test(value)) throw new ExtractError(`${flag}: must be an integer`);
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number <= 0) {
    throw new ExtractError(`${flag}: must be positive`);
  }
  return number;
}

function usage(): string {
  return 'Usage: bun extract_note_overlay.ts [--drive] [--output DIRECTORY] ' +
    '[--remote REMOTE] [--rclone COMMAND] [--dpi DPI] [PDF_OR_DIRECTORY ...]';
}

function optionValue(args: Array<string>, index: number, flag: string): string {
  const value = args[index + 1];
  if (value === undefined) throw new ExtractError(`${flag} requires a value`);
  return value;
}

function parseOptions(args: Array<string>): Options | null {
  const inputs: Array<string> = [];
  let isDrive = false;
  let remote = DEFAULT_REMOTE;
  let rclone = 'rclone-drive';
  let output = expandPath(DEFAULT_OUTPUT);
  let dpi = 180;
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === '--help' || argument === '-h') {
      console.log(usage());
      return null;
    }
    if (argument === '--drive') {
      isDrive = true;
    } else if (argument === '--output' || argument === '--dpi' ||
        argument === '--remote' || argument === '--rclone') {
      const value = optionValue(args, index, argument);
      index += 1;
      if (argument === '--output') output = expandPath(value);
      if (argument === '--dpi') dpi = positiveInteger(value, argument);
      if (argument === '--remote') remote = value;
      if (argument === '--rclone') rclone = value;
    } else if (argument?.startsWith('-')) {
      throw new ExtractError(`unrecognized argument: ${argument}`);
    } else if (argument !== undefined) {
      inputs.push(expandPath(argument));
    }
  }
  if (isDrive && inputs.length > 0) {
    throw new ExtractError('use either --drive or explicit PDF inputs, not both');
  }
  if (!isDrive && inputs.length === 0) {
    throw new ExtractError('supply --drive or at least one PDF or directory input');
  }
  return { inputs, isDrive, remote, rclone, output, dpi };
}

function parseDriveDocument(value: unknown, index: number, output: string): SourceDocument {
  const where = `Drive listing[${index}]`;
  const item = requireObject(value, where);
  const path = safeRelativePath(item.Path, `${where}.Path`);
  const name = requireText(item.Name, `${where}.Name`);
  const id = safeDocumentId(item.ID, `${where}.ID`);
  const size = requireInteger(item.Size, `${where}.Size`);
  if (size < 0 || !name.toLowerCase().endsWith('.pdf')) {
    throw new ExtractError(`${where} is not a valid PDF entry`);
  }
  requireText(item.MimeType, `${where}.MimeType`);
  const hashes = requireObject(item.Hashes, `${where}.Hashes`);
  return {
    id,
    path,
    title: name,
    size,
    modTime: requireText(item.ModTime, `${where}.ModTime`),
    rawPath: join(output, 'raw', ...path.split('/')),
    expectedSha256: requireSha256(hashes.sha256, `${where}.Hashes.sha256`),
  };
}

async function driveDocuments(options: Options): Promise<Array<SourceDocument>> {
  const listing = await run(options.rclone, [
    'lsjson', options.remote, '--recursive', '--files-only', '--hash',
    '--filter', '+ **.pdf', '--filter', '- *',
  ]);
  let decoded: unknown;
  try {
    decoded = JSON.parse(listing);
  } catch (error) {
    throw new ExtractError(`cannot parse Drive listing: ${errorMessage(error)}`, { cause: error });
  }
  const documents = requireList(decoded, 'Drive listing')
    .map((item, index) => parseDriveDocument(item, index, options.output));
  const ids = new Set<string>();
  const paths = new Set<string>();
  for (const document of documents) {
    if (ids.has(document.id)) throw new ExtractError(`duplicate Drive document ID: ${document.id}`);
    if (paths.has(document.path)) throw new ExtractError(`duplicate Drive path: ${document.path}`);
    ids.add(document.id);
    paths.add(document.path);
  }
  await mkdir(join(options.output, 'raw'), { recursive: true });
  await run(options.rclone, [
    'copy', options.remote, join(options.output, 'raw'), '--checksum',
    '--filter', '+ **.pdf', '--filter', '- *',
  ]);
  for (const document of documents) {
    if (!await isFile(document.rawPath)) {
      throw new ExtractError(`Drive PDF was not copied: ${document.path}`);
    }
    const actual = await fileSha256(document.rawPath);
    if (actual !== document.expectedSha256) {
      throw new ExtractError(`SHA-256 mismatch for Drive PDF: ${document.path}`);
    }
  }
  return documents.sort((left, right) => compareText(left.id, right.id));
}

async function discoverDirectory(
  directory: string,
  prefix: string,
  found: Array<{ absolute: string; relative: string }>,
): Promise<void> {
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((left, right) => compareText(left.name, right.name));
  for (const entry of entries) {
    const absolute = join(directory, entry.name);
    const normalized = prefix.length === 0 ? entry.name : `${prefix}/${entry.name}`;
    if (entry.isDirectory()) await discoverDirectory(absolute, normalized, found);
    else if (entry.isFile() && entry.name.toLowerCase().endsWith('.pdf')) {
      found.push({ absolute, relative: normalized });
    }
  }
}

async function localDocuments(inputs: Array<string>): Promise<Array<SourceDocument>> {
  const found: Array<{ absolute: string; relative: string }> = [];
  for (const input of inputs) {
    const absolute = resolve(input);
    let information: Stats;
    try {
      information = await stat(absolute);
    } catch (error) {
      throw new ExtractError(`input does not exist: ${input}`, { cause: error });
    }
    if (information.isDirectory()) {
      await discoverDirectory(absolute, '', found);
    } else if (information.isFile() && absolute.toLowerCase().endsWith('.pdf')) {
      found.push({ absolute, relative: basename(absolute) });
    } else {
      throw new ExtractError(`input is not a PDF file or directory: ${input}`);
    }
  }
  if (found.length === 0) throw new ExtractError('no PDF files found');
  const documents: Array<SourceDocument> = [];
  const ids = new Set<string>();
  const paths = new Set<string>();
  for (const item of found.sort((left, right) => compareText(left.relative, right.relative))) {
    if (paths.has(item.absolute)) continue;
    const normalized = safeRelativePath(item.relative.split(sep).join('/'), 'local PDF path');
    const id = safeDocumentId(sha256(`local:${normalized}`), 'local document ID');
    if (ids.has(id)) throw new ExtractError(`duplicate local PDF path: ${normalized}`);
    const information = await stat(item.absolute);
    ids.add(id);
    paths.add(item.absolute);
    documents.push({
      id,
      path: normalized,
      title: basename(normalized),
      size: information.size,
      modTime: information.mtime.toISOString(),
      rawPath: item.absolute,
      expectedSha256: null,
    });
  }
  return documents.sort((left, right) => compareText(left.id, right.id));
}

function parseDimensions(match: RegExpMatchArray, where: string): PageDimensions {
  const width = Number(match[1]);
  const height = Number(match[2]);
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
    throw new ExtractError(`${where} has invalid page dimensions`);
  }
  return { width, height };
}

async function describePdf(path: string): Promise<PdfDescription> {
  const output = await run('pdfinfo', ['-f', '1', '-l', MAX_PAGES.toString(), path]);
  const pageMatch = output.match(/^Pages:\s+(\d+)\s*$/m);
  if (pageMatch === null) throw new ExtractError(`pdfinfo did not report a page count: ${path}`);
  const pageCount = Number(pageMatch[1]);
  if (!Number.isSafeInteger(pageCount) || pageCount <= 0 || pageCount > MAX_PAGES) {
    throw new ExtractError(`PDF page count is outside 1..${MAX_PAGES}: ${path}`);
  }
  const dimensions = new Map<number, PageDimensions>();
  let common: PageDimensions | null = null;
  for (const line of output.split('\n')) {
    const individual = line.match(/^Page\s+(\d+) size:\s+([0-9.]+) x ([0-9.]+) pts/);
    if (individual !== null) {
      const number = Number(individual[1]);
      const size = line.match(/size:\s+([0-9.]+) x ([0-9.]+) pts/);
      if (size !== null) dimensions.set(number, parseDimensions(size, `page ${number}`));
      continue;
    }
    const general = line.match(/^Page size:\s+([0-9.]+) x ([0-9.]+) pts/);
    if (general !== null) common = parseDimensions(general, path);
  }
  const result: Array<PageDimensions> = [];
  for (let number = 1; number <= pageCount; number += 1) {
    const size = dimensions.get(number) ?? common;
    if (size === undefined || size === null) {
      throw new ExtractError(`pdfinfo did not report dimensions for page ${number}: ${path}`);
    }
    result.push(size);
  }
  return { pageCount, dimensions: result };
}

function parsePreviousPage(value: unknown, where: string): PreviousPage {
  const page = requireObject(value, where);
  const dimensionsValue = requireObject(page.dimensions, `${where}.dimensions`);
  const dimensions = {
    width: requireNumber(dimensionsValue.width_pt, `${where}.dimensions.width_pt`),
    height: requireNumber(dimensionsValue.height_pt, `${where}.dimensions.height_pt`),
  };
  return {
    id: requireText(page.id, `${where}.id`),
    number: requireInteger(page.number, `${where}.number`),
    zettelId: requireText(page.zettel_id, `${where}.zettel_id`),
    contentSha256: requireSha256(page.content_sha256, `${where}.content_sha256`),
    reviewSha256: requireSha256(page.review_sha256, `${where}.review_sha256`),
    dimensions,
    reviewPath: safeRelativePath(page.review_path, `${where}.review_path`),
    transcriptionPath: safeRelativePath(
      page.transcription_path,
      `${where}.transcription_path`,
    ),
  };
}

function parsePreviousDocument(value: unknown, where: string): PreviousDocument {
  const document = requireObject(value, where);
  return {
    id: safeDocumentId(document.id, `${where}.id`),
    sha256: requireSha256(document.sha256, `${where}.sha256`),
    pages: requireList(document.pages, `${where}.pages`)
      .map((page, index) => parsePreviousPage(page, `${where}.pages[${index}]`)),
  };
}

async function loadPreviousManifest(path: string, dpi: number): Promise<PreviousManifest> {
  const empty: PreviousManifest = { documents: [], artifacts: new Set<string>() };
  if (!await isFile(path)) return empty;
  try {
    const root = requireObject(JSON.parse(UTF8_DECODER.decode(await readFile(path))), 'manifest');
    const artifacts = new Set<string>();
    for (const item of requireList(root.artifacts, 'manifest.artifacts')) {
      artifacts.add(safeRelativePath(item, 'manifest artifact'));
    }
    if (root.schema !== MANIFEST_SCHEMA || root.dpi !== dpi) return { documents: [], artifacts };
    const documents = requireList(root.documents, 'manifest.documents')
      .map((document, index) => parsePreviousDocument(document, `manifest.documents[${index}]`));
    return { documents, artifacts };
  } catch {
    return empty;
  }
}

async function validReview(path: string, expectedSha256: string): Promise<boolean> {
  return await isFile(path) && await fileSha256(path) === expectedSha256;
}

async function processDocument(
  document: SourceDocument,
  actualSha256: string,
  description: PdfDescription | null,
  previous: PreviousDocument | undefined,
  output: string,
  dpi: number,
  temporary: string,
): Promise<{ record: JsonObject; artifacts: Array<string>; changed: number }> {
  const unchanged = previous !== undefined && previous.sha256 === actualSha256 &&
    previous.pages.length > 0;
  if (unchanged && description === null) {
    const artifacts: Array<string> = [];
    for (const page of previous.pages) {
      if (!await validReview(join(output, page.reviewPath), page.reviewSha256)) {
        throw new ExtractError(`declared review PNG is missing or invalid: ${page.reviewPath}`);
      }
      artifacts.push(page.reviewPath);
    }
    const record: JsonObject = {
      id: document.id,
      path: document.path,
      title: document.title,
      sha256: actualSha256,
      size: document.size,
      mod_time: document.modTime,
      raw_path: document.rawPath,
      page_count: previous.pages.length,
      pages: previous.pages.map((page) => ({
        id: page.id,
        number: page.number,
        zettel_id: page.zettelId,
        content_sha256: page.contentSha256,
        review_sha256: page.reviewSha256,
        dimensions: { width_pt: page.dimensions.width, height_pt: page.dimensions.height },
        review_path: page.reviewPath,
        transcription_path: page.transcriptionPath,
      })),
    };
    return { record, artifacts, changed: 0 };
  }
  if (description === null) throw new ExtractError(`missing PDF description: ${document.rawPath}`);
  const splitDirectory = join(temporary, document.id);
  await mkdir(splitDirectory, { recursive: true });
  await run('pdfseparate', [
    document.rawPath,
    join(splitDirectory, 'page-%d.pdf'),
  ]);
  const previousPages = new Map((previous?.pages ?? []).map((page) => [page.number, page]));
  const pages: Array<JsonObject> = [];
  const artifacts: Array<string> = [];
  let changed = 0;
  for (let number = 1; number <= description.pageCount; number += 1) {
    const dimensions = description.dimensions[number - 1];
    if (dimensions === undefined) throw new ExtractError(`missing dimensions for page ${number}`);
    const splitPath = join(splitDirectory, `page-${number}.pdf`);
    const contentSha256 = await fileSha256(splitPath);
    const old = previousPages.get(number);
    const name = pageName(number);
    const reviewPath = `review/${document.id}/page-${name}.png`;
    const reviewAbsolute = join(output, reviewPath);
    let reviewSha256 = old?.reviewSha256;
    if (old === undefined || old.contentSha256 !== contentSha256 ||
        reviewSha256 === undefined || !await validReview(reviewAbsolute, reviewSha256)) {
      await mkdir(dirname(reviewAbsolute), { recursive: true });
      const renderedBase = join(splitDirectory, `review-${name}`);
      await run('pdftoppm', [
        '-singlefile', '-png', '-r', dpi.toString(), splitPath, renderedBase,
      ]);
      const rendered = `${renderedBase}.png`;
      if (!await isFile(rendered)) throw new ExtractError(`pdftoppm did not create page ${number}`);
      if (await writeIfChanged(reviewAbsolute, await readFile(rendered))) changed += 1;
      reviewSha256 = await fileSha256(reviewAbsolute);
    }
    const id = `${document.id}-page-${name}`;
    const zettelId = `note-overlay-${sha256(document.id).slice(0, 16)}-${name}`;
    const transcriptionPath = `transcriptions/${zettelId}.md`;
    pages.push({
      id,
      number,
      zettel_id: zettelId,
      content_sha256: contentSha256,
      review_sha256: reviewSha256,
      dimensions: { width_pt: dimensions.width, height_pt: dimensions.height },
      review_path: reviewPath,
      transcription_path: transcriptionPath,
    });
    artifacts.push(reviewPath);
  }
  return {
    record: {
      id: document.id,
      path: document.path,
      title: document.title,
      sha256: actualSha256,
      size: document.size,
      mod_time: document.modTime,
      raw_path: document.rawPath,
      page_count: description.pageCount,
      pages,
    },
    artifacts,
    changed,
  };
}

function assertSafeReviewArtifact(path: string): void {
  const safe = safeRelativePath(path, 'previous manifest artifact');
  if (!safe.startsWith('review/') || !(safe.endsWith('.png') || safe.endsWith('.svg'))) {
    throw new ExtractError(`unsafe review artifact in previous manifest: ${path}`);
  }
}

async function main(): Promise<void> {
  const options = parseOptions(process.argv.slice(2));
  if (options === null) return;
  const manifestPath = join(options.output, 'manifest.json');
  const previous = await loadPreviousManifest(manifestPath, options.dpi);
  const documents = options.isDrive
    ? await driveDocuments(options)
    : await localDocuments(options.inputs);
  const previousById = new Map(previous.documents.map((document) => [document.id, document]));
  const temporary = await mkdtemp(join(tmpdir(), 'note-overlay-'));
  try {
    const records: Array<JsonObject> = [];
    const artifacts = new Set<string>();
    let changed = 0;
    for (const document of documents) {
      const actualSha256 = await fileSha256(document.rawPath);
      if (document.expectedSha256 !== null && actualSha256 !== document.expectedSha256) {
        throw new ExtractError(`SHA-256 mismatch for PDF: ${document.path}`);
      }
      const old = options.isDrive ? previousById.get(document.id) : undefined;
      let unchanged = old?.sha256 === actualSha256;
      if (old !== undefined && unchanged) {
        for (const page of old.pages) {
          if (!await validReview(join(options.output, page.reviewPath), page.reviewSha256)) {
            unchanged = false;
            break;
          }
        }
      }
      const description = unchanged ? null : await describePdf(document.rawPath);
      const result = await processDocument(
        document,
        actualSha256,
        description,
        old,
        options.output,
        options.dpi,
        temporary,
      );
      records.push(result.record);
      for (const artifact of result.artifacts) artifacts.add(artifact);
      changed += result.changed;
    }
    let removed = 0;
    for (const artifact of [...previous.artifacts].sort()) {
      if (artifacts.has(artifact)) continue;
      assertSafeReviewArtifact(artifact);
      const path = join(options.output, artifact);
      if (await isFile(path)) {
        await unlink(path);
        removed += 1;
      }
    }
    const manifest = {
      schema: MANIFEST_SCHEMA,
      source: options.isDrive
        ? { type: 'drive', remote: options.remote }
        : { type: 'local' },
      dpi: options.dpi,
      artifacts: [...artifacts].sort(),
      documents: records,
    };
    const bytes = Buffer.from(`${JSON.stringify(canonicalize(manifest), null, 2)}\n`, 'utf8');
    if (await writeIfChanged(manifestPath, bytes)) changed += 1;
    console.log(
      `Processed ${documents.length} PDFs. Wrote ${changed} changed artifacts; ` +
      `removed ${removed} stale review artifacts. Manifest: ${manifestPath}`,
    );
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
}

try {
  await main();
} catch (error) {
  console.error(`extract_note_overlay: ${errorMessage(error)}`);
  process.exitCode = 1;
}
