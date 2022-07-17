#!/bin/bash
PROJECTKEY="MYPROJECTKEY"
QGSTATUS=`curl -s -u admin:YOURPASSWORDHERE https://sonar.example.co/api/qualitygates/project_status\?projectKey\=$PROJECTKEY | jq '.projectStatus.status' | tr -d '"'`
#QGSTATUS=`curl --location --request GET 'https://sonar.example.com/api/qualitygates/project_status?projectKey=$PROJECTKEY' --header 'Authorization: Basic BASE64TOKEN' | jq '.projectStatus.status' | tr -d '"'`
if [ "$QGSTATUS" = "OK" ]
then
echo "Status is OK"
echo "Sonar scanning has successfully ended with the status 'OK'"
elif [ "$QGSTATUS" = "WARN" ]
then
echo "Status is WARN. Check out the quality of the products at https://sonar.example.com/dashboard?id=MYPROJECTKEY"
exit 1 # terminate and indicate error
elif [ "$QGSTATUS" = "ERROR" ]
then
echo "Status is ERROR. Check out the quality of the products at https://sonar.example.com/dashboard?id=MYPROJECTKEY"
exit 1 # terminate and indicate error
fi
