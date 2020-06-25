#!/bin/bash

install_zip_dependencies(){
	echo "Zipping dependencies..."
	zip -r dependencies.zip ${INPUT_DEPENDENCY_DIRECTORY}
}

publish_dependencies_as_layer(){
	echo "Publishing dependencies as a layer..."
	local result=$(aws lambda publish-layer-version --layer-name "${INPUT_LAMBDA_LAYER_ARN}" --zip-file fileb://dependencies.zip)
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm dependencies.zip
}

publish_function_code(){
	echo "Deploying the code itself..."
	cd src/aws_lambdas
	zip -r ../../code.zip *
	cd ../..
	aws lambda update-function-code --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --zip-file fileb://code.zip
}

update_function_layers(){
	echo "Using the layer in the function..."
	aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers "arn:aws:lambda:eu-west-1:399891621064:layer:AWSLambda-Python37-SciPy1x:22" "${INPUT_LAMBDA_LAYER_ARN}:${LAYER_VERSION}"
}

deploy_lambda_function(){
	install_zip_dependencies
	publish_dependencies_as_layer
	publish_function_code
	update_function_layers
}

deploy_lambda_function
echo "Done."
