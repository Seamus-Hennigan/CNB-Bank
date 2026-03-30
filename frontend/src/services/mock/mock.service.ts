export function isMockMode(): boolean {
  return process.env.REACT_APP_USE_MOCK_DATA === 'true';
}

export function mockDelay<T>(data: T, ms = 400): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(data), ms));
}
