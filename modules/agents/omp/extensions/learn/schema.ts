export interface Schema<T> {
  assert(data: unknown): T;
}
