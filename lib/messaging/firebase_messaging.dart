class FirebaseMessaging {
  static final String defaultVapidKey =
      'BDOU99-h67HcA6JeFXHbSNMu7e2yNNu3RzoMj8TM4W88jITfq7ZmPvIM1Iv-4_l2LxQcYwhqby2xGpWwzjfAnG4';
  static final String apiEndpoint =
      'https://fcmregistrations.googleapis.com/v1';
  static final String fcmMsg = 'FCM_MSG';
  static final String tag = 'FirebaseMessaging: ';
  static final Map<String, String> fcmErrorMap = {
    'missing-app-config-values': 'Missing App configuration value:',
    'only-available-in-window': 'This method is available in a Window context.',
    'only-available-in-sw':
        'This method is available in a service worker context.',
    'permission-default':
        'The notification permission was not granted and dismissed instead.',
    'permission-blocked':
        'The notification permission was not granted and blocked instead.',
    'unsupported-browser':
        "This browser doesn't support the API's required to use the firebase SDK.",
    'failed-service-worker-registration':
        'We are unable to register the default service worker.',
    'token-subscribe-failed':
        'A problem occurred while subscribing the user to FCM:',
    'token-subscribe-no-token':
        'FCM returned no token when subscribing the user to push.',
    'token-unsubscribe-failed': 'A problem occurred while unsubscribing the '
        'user from FCM: ',
    'token-update-failed':
        'A problem occurred while updating the user from FCM:',
    'token-update-no-token':
        'FCM returned no token when updating the user to push.',
    'invalid-bg-handler':
        'The useServiceWorker() method may only be called once and must be '
            'called before calling getToken() to ensure your service worker is used.',
    'use-sw-after-get-token':
        'The input to useServiceWorker() must be a ServiceWorkerRegistration.',
    'invalid-sw-registration':
        'The input to setBackgroundMessageHandler() must be a function.',
    'use-vapid-key-after-get-token': 'The public VAPID key must be a string.',
    'invalid-vapid-key':
        'The usePublicVapidKey() method may only be called once and must be '
            'called before calling getToken() to ensure your VAPID key is used.'
  };
}
