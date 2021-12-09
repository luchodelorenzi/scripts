//Part 1. Return Token
//Define the JSON request body
var jsonBody = {};
//Fill in the values into the jsonBody
jsonBody.username = restAuthUsername;
jsonBody.password = restAuthPassword;
jsonRequestBody = JSON.stringify(jsonBody);
System.log(jsonRequestBody)
//Create a new HTTP REST Request object for the REST host that was provided
var request = restHost.createRequest("POST", "/csp/gateway/am/api/login?access_token", jsonRequestBody);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
System.log(request)
//Attempt to execute the REST request
try {
    response = request.execute();
    jsonObject = JSON.parse(response.contentAsString);
    try{
	    var tokenResponse = jsonObject.refresh_token;
	    System.log("token: " + tokenResponse);
    } catch (ex) {
	throw ex + " No valid token";
    }
}
catch (e) {
    throw "There was an error executing the REST call:" + e;
}
// Get IaaS token
var newstring = '{ "refreshToken": "'+jsonObject.refresh_token+'"}'

var request = restHost.createRequest("POST", "/iaas/api/login", newstring);
request.contentType = "application/json";
request.setHeader("Authorization", "Bearer " + tokenResponse);
 
//Attempt to execute the REST request
try {
    response = request.execute();
    jsonObject = JSON.parse(response.contentAsString);
    try{
	    var tokenResponse = jsonObject.token;
	    System.log("token: " + tokenResponse);
    } catch (ex) {
	throw ex + " No valid token";
    }
}
catch (e) {
    throw "There was an error executing the REST call:" + e;
}

//delete Deployment
System.log(deploymentId)
var request = restHost.createRequest("DELETE", "/deployment/api/deployments/"+deploymentId);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
request.setHeader("Authorization", "Bearer " + tokenResponse)
 
//Attempt to execute the REST request
try {
    response = request.execute();
    jsonObject = JSON.parse(response.contentAsString);
    System.log(response.contentAsString)
}
catch (e) {
    throw "There was an error executing the REST call:" + e;
}
