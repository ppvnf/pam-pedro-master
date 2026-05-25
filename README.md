# guacamole-pam-pedro

PAM (Privileged Access Management) solution using Apache Guacamole as the remote desktop gateway, with automated build and deployment powered by GitLab CI/CD, Podman, and Ansible

This repository is intended for demonstration purposes only. 

The GitLab pipeline (https://gitlab.com/pedro-pam/pam-guacamole/-/pipelines) works, except security testing which is only available in the premium version.

The Docker images are available on https://gitlab.com/pedro-pam/pam-guacamole/container_registry


![home page](screenshots/home.png)


## Requirements

- Linux
- Podman
- Ansible
- OpenSSL
- Skopeo (required only for local build)
- Firefox (recommended for certificate import)

## Quick Start

Clone the repository and navigate to the Ansible folder:

```sh
git clone https://github.com/ppvnf/pam-pedro-master.git
cd pam-pedro-master/ansible
```

Deploy the Guacamole image (pulls image from remote):

```sh
ansible-playbook deploy_remote.yml
```
if you get an error about no policy.json file, create one and make sure unsigned repo/images are accepted:

```sh
echo '{"default":[{"type":"insecureAcceptAnything"}]}' | sudo tee /etc/containers/policy.json
```

Alternatively the image can be built locally:

```sh
ansible-playbook deploy_local.yml
```

It will print instructions and credentials at the end. 

![deployment instructions](screenshots/deployment_instructions.png)

Import the mTLS certificate (saved in the current directory) into Firefox

![mtls install](screenshots/mtls.png)

Then log in as guacadmin at https://localhost/guacamole to set up TOTP

![totp](screenshots/totp.png)

Once TOTP is configured, run the provisioning playbook:

```sh
ansible-playbook provision.yml
```

Provide the TOTP code, the certificate password and the guacadmin password before continuing.

![provision instructions](screenshots/provision.png)

Refresh the page and you should be able to see and connect to the demo containers using the guacadmin account.

![demo containers](screenshots/containers.png)

Session recordings are enabled by default and available at:
https://localhost/guacamole/#/settings/postgresql/history

![recording](screenshots/recording.png)

![recording 2](screenshots/recording2.png)

## SAML / Microsoft Entra SSO

SAML is disabled by default. To enable it:

1. Create an enterprise application in Microsoft Entra and configure it as described in section 5.4.2.3. SAML extension.
2. Enable SAML in `ansible/roles/deploy/defaults/main.yml`.

![saml](screenshots/saml.png)

## Notes

- The GitLab CI/CD pipeline is not functional on GitHub.

![pipeline](screenshots/pipeline.png)

- The company icons in `build/extensions/custom-homepage/images` have been replaced for this public release.

![icons](screenshots/icons.png)

<a href="https://www.flaticon.com/free-icons/spiderman" title="Spiderman icons">Spiderman icons created by egorpolyakov - Flaticon</a>