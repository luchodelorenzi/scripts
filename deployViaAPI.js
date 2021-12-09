//REFRESH TOKEN
var jsonBody = {};
//Fill in the values into the jsonBody
jsonBody.username = restAuthUsername;
jsonBody.password = restAuthPassword;
jsonRequestBody = JSON.stringify(jsonBody);
var request = restHost.createRequest("POST", "/csp/gateway/am/api/login?access_token", jsonRequestBody);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
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
//IaaS token
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

//Execute Deployment
var blueprintId = "01b5b4db-48b6-4b29-b062-a7dc1c5d9c93" // hardcoded master template
var blueprintInputs = {}
blueprintInputs.instances = instances
blueprintInputs.environment = environment
blueprintInputs.image = image
blueprintInputs.network = network
blueprintInputs.flavor = flavor
var blueprintBody = {}
blueprintBody.blueprintId = blueprintId
blueprintBody.blueprintVersion = "1"
blueprintBody.deploymentName = realDeploymentName
blueprintBody.projectId = projectId
blueprintBody.reason = "X"
blueprintBody.inputs = blueprintInputs
blueprintBodyString = JSON.stringify(blueprintBody)
System.log(blueprintBodyString)
var request = restHost.createRequest("POST", "/blueprint/api/blueprint-requests", blueprintBodyString);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
request.setHeader("Authorization", "Bearer " + tokenResponse)
 
//Attempt to execute the REST request
try {
    response = request.execute();
    jsonObject = JSON.parse(response.contentAsString);
    var deploymentId = jsonObject.deploymentId
    System.log(jsonObject.deploymentId)
    System.log(response.contentAsString)
}
catch (e) {
    throw "There was an error executing the REST call:" + e;
}
System.log ("Deployment id: " + deploymentId)
//Parse deployment status

var request = restHost.createRequest("GET","deployment/api/deployments/" + deploymentId);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
request.setHeader("Authorization", "Bearer " + tokenResponse)
do{
    System.sleep(60 * 1000)
    try {
            response = request.execute();
            System.log (response.statusCode);
            jsonObject = JSON.parse(response.contentAsString);
            System.log (jsonObject);
            System.log(response.contentAsString)
            System.log ("REST request executed successfully");
            System.log ("Current deployment status is: " + jsonObject.status)
        }
        catch (e) {
            System.error("Error executing the REST operation: " + e);
        }
}
while (jsonObject.status != 'CREATE_SUCCESSFUL')
System.log("Deployment is now ready to change owner")

//CHANGE USER
var ownerBodyString = JSON.stringify({
            "actionId": "Deployment.ChangeOwner",
            "targetId": deploymentId,
            "inputs": {
                "New Owner": ownerId
            }
        })


var request = restHost.createRequest("POST", "/deployment/api/deployments/"+deploymentId+"/requests", ownerBodyString);
request.contentType = "application/json";
request.setHeader("accept", "application/json");
request.setHeader("Authorization", "Bearer " + tokenResponse)

//Attempt to execute the REST request
try {
    response = request.execute();
    System.log (response.statusCode);
    jsonObject = JSON.parse(response.contentAsString);
    System.log(response.contentAsString)
}
catch (e) {
    throw "There was an error executing the REST call:" + e;
}
