{
  apiVersion: 'v1',
  kind: 'Template',
  metadata: { name: 'observatorium' },
  objects: [
      {
          apiVersion: 'v1',
          kind: 'Secret',
          metadata+: {
            name: 'observatorium-observatorium-api',
          },
          type: 'Opaque',
          data: {
            'client-id': "${CLIENT_ID}",
            'client-secret': "${CLIENT_SECRET}",
            'issuer-url': "https://sso.redhat.com/auth/realms/redhat-external",
            'tenants.yaml': {
                tenants: [
                    { "id": "0fc2b00e-201b-4c17-b9f2-19d91adc4fd2",
                      "name": "rhobs",
                      "oidc": {
                        "clientID": "${CLIENT_ID}",
                        "clientSecret": "${CLIENT_SECRET}",
                        "issuerURL": "https://sso.redhat.com/auth/realms/redhat-external",
                        "redirectURL": "https://observatorium.api.stage.openshift.com/oidc/rhobs/callback",
                        "usernameClaim": "preferred_username",
                        "groupClaim": "email",
                      },
                    },
                    { "id": "FB870BF3-9F3A-44FF-9BF7-D7A047A52F43",
                      "name": "telemeter",
                      "oidc": {
                        "clientID": "${CLIENT_ID}",
                        "clientSecret": "${CLIENT_SECRET}",
                        "issuerURL": "https://sso.redhat.com/auth/realms/redhat-external",
                        "redirectURL": "https://observatorium.api.stage.openshift.com/oidc/telemeter/callback",
                        "usernameClaim": "preferred_username",
                      },
                    },
                    { "id": "AC879303-C60F-4D0D-A6D5-A485CFD638B8",
                      "name": "dptp",
                      "oidc": {
                        "clientID": "${CLIENT_ID}",
                        "clientSecret": "${CLIENT_SECRET}",
                        "issuerURL": "https://sso.redhat.com/auth/realms/redhat-external",
                        "redirectURL": "https://observatorium.api.stage.openshift.com/oidc/dptp/callback",
                        "usernameClaim": "preferred_username",
                      },
                      "opa": {
                        "url": "http://127.0.0.1:8082/v1/data/observatorium/allow",
                      },
                    }
                ]
            },
          },
      },
  ],
  parameters: [
      { name: "CLIENT_ID" },
      { name: "CLIENT_SECRET" },
  ]
}
