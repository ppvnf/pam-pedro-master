# guacamole-pam-pedro

This bachelor thesis focuses on building a PAM (Privileged Access Management) system using Apache Guacamole remote desktop gateway service.

It is possible to run it locally on Linux using Podman, Ansible and Firefox.
 
Clone the git repository and cd to the ansible folder.
 
run: ansible-playbook deploy_local.yml
 
This command will build and deploy the guacamole image.
 
At the end it will give you instructions on how to import the certificate and set up TOTP.

After you set up TOTP and save the password for guacadmin and the one for the certificate run: ansible-playbook provision.yml and provide those passwords.
 
At the end, if you refresh the page, you should be able to see and connect to the demo containers using the guacadmin account.

The Gitlab pipeline obviously doesn't work on Github.

SAML is disabled by default, although it is working already. To configure SAML, besides creating an APP on Azure AD, you need to modify ansible/roles/remote/defaults/main.yml.example and enable it in ansible/roles/deploy/defaults/main.yml

<a href="https://www.flaticon.com/free-icons/spiderman" title="Spiderman icons">Spiderman icons created by egorpolyakov - Flaticon</a>
