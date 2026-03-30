import {
  signIn,
  signOut,
  fetchAuthSession,
  fetchUserAttributes,
} from 'aws-amplify/auth';
import { AuthUser } from '../types';

export async function loginWithCognito(email: string, password: string): Promise<void> {
  await signIn({ username: email, password });
}

export async function logoutFromCognito(): Promise<void> {
  await signOut();
}

export async function getCurrentUser(): Promise<AuthUser | null> {
  try {
    const [session, attrs] = await Promise.all([
      fetchAuthSession(),
      fetchUserAttributes(),
    ]);
    const groups =
      (session.tokens?.idToken?.payload?.['cognito:groups'] as string[]) ?? [];
    return {
      sub: attrs.sub ?? '',
      email: attrs.email ?? '',
      given_name: attrs.given_name ?? '',
      family_name: attrs.family_name ?? '',
      groups,
    };
  } catch {
    return null;
  }
}

export async function hasActiveSession(): Promise<boolean> {
  try {
    const session = await fetchAuthSession({ forceRefresh: false });
    return !!session.tokens?.idToken;
  } catch {
    return false;
  }
}
