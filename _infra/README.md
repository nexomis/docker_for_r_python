# Setup Infra

## configure SSO


```
$aws configure sso
SSO session name (Recommended): nexomis
SSO start URL [None]: https://nexomis.awsapps.com/start
SSO region [None]: eu-west-3
SSO registration scopes [sso:account:access]:
Attempting to automatically open the SSO authorization page in your default browser.
If the browser does not open or you wish to use a different device to authorize this request, open the following URL:

https://device.sso.eu-west-3.amazonaws.com/

Then enter the code:

RRHQ-BXRK
There are X AWS accounts available to you.
Using the account ID XXXXXXXXXXXX
The only role available to you is: PowerUserAccess
Using the role name "PowerUserAccess"
CLI default client Region [eu-west-3]:
CLI default output format [None]:
CLI profile name [PowerUserAccess-XXXXXXXXXXXX]: nexomis-compute

To use this profile, specify the profile name using --profile, as shown:

aws s3 ls --profile nexomis-compute
```

## Configure 

