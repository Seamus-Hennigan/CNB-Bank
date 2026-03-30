import { Notification, NotificationPreferences } from '../types';
import { isMockMode, mockDelay } from './mock/mock.service';
import { mockNotifications, mockNotificationPreferences } from './mock/mock-notifications';
import { apiGet, apiPut } from './api.service';

export async function getNotifications(): Promise<Notification[]> {
  if (isMockMode()) return mockDelay([...mockNotifications]);
  return apiGet<Notification[]>('/notifications');
}

export async function markNotificationRead(id: string): Promise<void> {
  if (isMockMode()) {
    const n = mockNotifications.find((x) => x.id === id);
    if (n) n.read = true;
    return mockDelay(undefined as void);
  }
  await apiPut(`/notifications/${id}/read`, {});
}

export async function getNotificationPreferences(): Promise<NotificationPreferences> {
  if (isMockMode()) return mockDelay({ ...mockNotificationPreferences });
  return apiGet<NotificationPreferences>('/notifications/preferences');
}

export async function updateNotificationPreferences(
  prefs: Partial<NotificationPreferences>
): Promise<NotificationPreferences> {
  if (isMockMode()) return mockDelay({ ...mockNotificationPreferences, ...prefs });
  return apiPut<NotificationPreferences>('/notifications/preferences', prefs);
}
