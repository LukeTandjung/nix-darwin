import { Database } from 'bun:sqlite';
import { appendFile, readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

const MAX_GRAPH_FILE_BYTES = 16 * 1024 * 1024;
const MAX_GRAPH_LINE_COUNT = 20_000;
const MAX_LOCK_ATTEMPT_COUNT = 100;
const LOCK_RETRY_MS = 100;

export interface LedgerSnapshot {
  readonly values: Array<unknown>;
  readonly sizeBytes: number;
  readonly lineCount: number;
}

export async function readJsonLines(path: string): Promise<LedgerSnapshot> {
  const empty = { values: [], sizeBytes: 0, lineCount: 0 };
  try {
    const metadata = await stat(path);
    if (metadata.size > MAX_GRAPH_FILE_BYTES) {
      throw new Error(`Graph file exceeds size limit: ${path}`);
    }
    const content = await readFile(path, 'utf8');
    const values = content
      .split('\n')
      .filter((line) => line.trim().length > 0)
      .map((line) => JSON.parse(line));
    if (values.length > MAX_GRAPH_LINE_COUNT) {
      throw new Error(`Graph file exceeds line limit: ${path}`);
    }
    return { values, sizeBytes: metadata.size, lineCount: values.length };
  } catch (error) {
    if (hasErrorCode(error, 'ENOENT')) return empty;
    throw error;
  }
}

export function createAssertionPayload(
  path: string,
  assertions: Array<unknown>,
  current: LedgerSnapshot,
): string {
  if (assertions.length === 0) return '';
  const payload = `${assertions.map((assertion) => JSON.stringify(assertion)).join('\n')}\n`;
  if (current.sizeBytes + Buffer.byteLength(payload) > MAX_GRAPH_FILE_BYTES) {
    throw new Error(`Graph append would exceed the byte limit: ${path}`);
  }
  if (current.lineCount + assertions.length > MAX_GRAPH_LINE_COUNT) {
    throw new Error(`Graph append would exceed the line limit: ${path}`);
  }
  return payload;
}

export async function appendPayload(
  path: string,
  payload: string,
): Promise<void> {
  if (payload.length === 0) return;
  await appendFile(path, payload, { encoding: 'utf8', mode: 0o600 });
}

export async function withGraphLock<T>(
  root: string,
  operation: () => Promise<T>,
): Promise<T> {
  const database = new Database(join(root, '.write-lock.sqlite'));
  try {
    database.exec('PRAGMA busy_timeout = 0');
    let isAcquired = false;
    for (let attempt = 0; attempt < MAX_LOCK_ATTEMPT_COUNT; attempt += 1) {
      try {
        database.exec('BEGIN IMMEDIATE');
        isAcquired = true;
        break;
      } catch (error) {
        if (!hasErrorCode(error, 'SQLITE_BUSY')) throw error;
        await delay(LOCK_RETRY_MS);
      }
    }
    if (!isAcquired)
      throw new Error('Graph write lock timed out after 10 seconds.');
    const result = await operation();
    database.exec('COMMIT');
    return result;
  } catch (error) {
    if (database.inTransaction) database.exec('ROLLBACK');
    throw error;
  } finally {
    database.close();
  }
}

function hasErrorCode(
  error: unknown,
  code: string,
): error is Error & { code: string } {
  return error instanceof Error && 'code' in error && error.code === code;
}
