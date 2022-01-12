'use strict';
const AWS = require('aws-sdk');
console.log('Loading function');
let name = "Manual";
// Making an entry in Data S3 Bucket (Sample to demonstrate how to use S3 Bucket from Lambda)
console.log('The S3 Bucket Name :', process.env.S3_DATA_BUCKET);
var file_name = name+"/"+Date.now()+".txt"
var file_body = "name:"+name+" access_time:"+new Date().toISOString()
var s3 = new AWS.S3();
    //configuring parameters
    var params = {
        Bucket: process.env.S3_DATA_BUCKET,
        Body : file_body,
        Key : file_name
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

exports.handler = async (event) => {
    let name = "There";
    
    let responseCode = 200;
    console.log("request: " + JSON.stringify(event));
    
    if (event.queryStringParameters && event.queryStringParameters.name) {
        console.log("Received name: " + event.queryStringParameters.name);
        name = event.queryStringParameters.name;
    }
     
    let greeting = `Hello ${name} !`;

    // Making an entry in Data S3 Bucket (Sample to demonstrate how to use S3 Bucket from Lambda)
    console.log('The S3 Bucket Name :', process.env.S3_DATA_BUCKET);
    var file_name = name+"/"+Date.now()+".txt"
    var file_body = "name:"+name+" access_time:"+new Date().toISOString()
    var s3 = new AWS.S3();
        //configuring parameters
        var params = {
            Bucket: process.env.S3_DATA_BUCKET,
            Body : file_body,
            Key : file_name
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

    // API Response   
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