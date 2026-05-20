# guacamole-pam-pedro

A bachelor thesis project implementing a PAM (Privileged Access Management) 
solution using Apache Guacamole as the remote desktop gateway, with automated 
build and deployment powered by GitLab CI/CD, Podman, and Ansible.

## Requirements

- AlmaLinux 9 (the distro shouldn't matter)
- Podman
- Ansible
- Firefox (easiest to set up certificates)

## Quick Start

Clone the repository and navigate to the Ansible folder:

```sh
git clone github.com:ppvnf/pam-pedro-master.git
cd pam-pedro-master/ansible
```

Deploy the Guacamole image:

```sh
ansible-playbook deploy_local.yml
```

At the end of the deployment, follow the printed instructions to import 
the mTLS certificate into Firefox and set up TOTP for the guacadmin account by accessing https://localhost/guacamole
Don 't forget to save the certificate and admin passwords

Once TOTP is configured, run the provisioning playbook and provide the passwords when prompted

```sh
ansible-playbook provision.yml
```

Refresh the page and you should be able to see and connect to the demo 
containers using the guacadmin account.

## SAML / Microsoft Entra SSO

SAML is disabled by default. To enable it:

1. Create an enterprise application in Azure AD and configure it as described 
   in the thesis.
2. Fill in your settings in `ansible/roles/remote/defaults/main.yml.example`.
3. Enable SAML in `ansible/roles/deploy/defaults/main.yml`.

## Notes

- The GitLab CI/CD pipeline is not functional on GitHub.
<a href="https://www.flaticon.com/free-icons/spiderman" title="Spiderman icons">Spiderman icons created by egorpolyakov - Flaticon</a>
