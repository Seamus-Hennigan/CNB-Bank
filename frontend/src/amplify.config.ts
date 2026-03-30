import { Amplify } from 'aws-amplify';

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: process.env.REACT_APP_COGNITO_USER_POOL_ID ?? '',
      userPoolClientId: process.env.REACT_APP_COGNITO_CLIENT_ID ?? '',
      loginWith: {
        oauth: {
          domain: process.env.REACT_APP_COGNITO_DOMAIN ?? '',
          scopes: ['openid', 'email', 'profile'],
          redirectSignIn: [window.location.origin + '/callback'],
          redirectSignOut: [window.location.origin + '/login'],
          responseType: 'code',
        },
      },
    },
  },
});
