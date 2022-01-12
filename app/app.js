'use strict';
const AWS = require('aws-sdk');
console.log('Loading function');
 
exports.handler = async (event) => {
    let name = "There";
    
    let responseCode = 200;
    console.log("request: " + JSON.stringify(event));
    
    if (event.queryStringParameters && event.queryStringParameters.name) {
        console.log("Received name: " + event.queryStringParameters.name);
        name = event.queryStringParameters.name;
    }
    
 
    let greeting = `Hello ${name} !`;

    // Making an entry in DATA Bucket
    console.log('The S3 Bucket Name :', process.env.S3_DATA_BUCKET);
    var s3 = new AWS.S3();
    var filePath = event.queryStringParameters.name+".txt";
    fs.writeFileSync(filePath, event.queryStringParameters.name);

    //configuring parameters
    var params = {
        Bucket: process.env.S3_DATA_BUCKET,
        Body : fs.createReadStream(filePath),
        Key : event.queryStringParameters.name+"/"+Date.now()+"_"+path.basename(filePath)
    };

    s3.upload(params, function (err, data) {
        //handle error
        if (err) {
          console.log("Error", err);
        }
      
        //success
        if (data) {
          console.log("Uploaded in:", data.Location);
        }
      });

    let responseBody = {
        message: greeting
    };
    
    // The output from a Lambda proxy integration must be 
    // in the following JSON object. The 'headers' property 
    // is for custom response headers in addition to standard 
    // ones. The 'body' property  must be a JSON string. For 
    // base64-encoded payload, you must also set the 'isBase64Encoded'
    // property to 'true'.
    let response = {
        statusCode: responseCode,
        headers: {
            "x-custom-header" : "my custom header value"
        },
        body: JSON.stringify(responseBody)
    };
    console.log("response: " + JSON.stringify(response))
    return response;
};