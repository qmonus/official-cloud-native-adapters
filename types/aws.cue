package aws

import "qmonus.net/adapter/official/types:base"

#AwsProvider: {
	base.#Resource
	type: "pulumi:providers:aws"
}

#QvsManagedLabel: {
	"managed-by": "Qmonus Value Stream"
	{[string]: string}
}

#AwsAppRunnerCustomDomainAssociation: {
	base.#Resource
	type: "aws:apprunner:CustomDomainAssociation"
}

#AwsAppRunnerService: {
	base.#Resource
	type: "aws:apprunner:Service"
	properties: tags: #QvsManagedLabel
}

#AwsCertificate: {
	base.#Resource
	type: "aws:acm:Certificate"
	properties: tags: #QvsManagedLabel
}

#AwsCloudFrontDistribution: {
	base.#Resource
	type: "aws:cloudfront:Distribution"
	properties: tags: #QvsManagedLabel
}

#AwsCloudFrontOAC: {
	base.#Resource
	type: "aws:cloudfront:OriginAccessControl"
}

#AwsCloudwatchLogGroup: {
	base.#Resource
	type: "aws:cloudwatch:LogGroup"
	properties: tags: #QvsManagedLabel
}

#AwsCloudwatchLogResourcePolicy: {
	base.#Resource
	type: "aws:cloudwatch:LogResourcePolicy"
}

#AwsEcrRepository: {
	base.#Resource
	type: "aws:ecr:Repository"
	properties: tags: #QvsManagedLabel
}

#AwsIamRole: {
	base.#Resource
	type: "aws:iam:Role"
	properties: tags: #QvsManagedLabel
}

#AwsIamRolePolicy: {
	base.#Resource
	type: "aws:iam:RolePolicy"
}

#AwsInternetGateway: {
	base.#Resource
	type: "aws:ec2:InternetGateway"
	properties: tags: #QvsManagedLabel
}

#AwsRdsCluster: {
	base.#Resource
	type: "aws:rds:Cluster"
	properties: tags: #QvsManagedLabel
}

#AwsRdsClusterInstance: {
	base.#Resource
	type: "aws:rds:ClusterInstance"
	properties: tags: #QvsManagedLabel
}

#AwsRdsClusterParameterGroup: {
	base.#Resource
	type: "aws:rds:ClusterParameterGroup"
	properties: tags: #QvsManagedLabel
}

#AwsRdsSubnetGroup: {
	base.#Resource
	type: "aws:rds:SubnetGroup"
	properties: tags: #QvsManagedLabel
}

#AwsRoute53Record: {
	base.#Resource
	type: "aws:route53:Record"
}

#AwsRouteTable: {
	base.#Resource
	type: "aws:ec2:RouteTable"
	properties: tags: #QvsManagedLabel
}

#AwsRouteTableAssociation: {
	base.#Resource
	type: "aws:ec2:RouteTableAssociation"
}

#AwsS3BucketPolicy: {
	base.#Resource
	type: "aws:s3:BucketPolicy"
}

#AwsS3BucketV2: {
	base.#Resource
	type: "aws:s3:BucketV2"
	properties: tags: #QvsManagedLabel
}

#AwsSecretsManagerSecret: {
	base.#Resource
	type: "aws:secretsmanager:Secret"
	properties: tags: #QvsManagedLabel
}

#AwsSecretsManagerSecretVersion: {
	base.#Resource
	type: "aws:secretsmanager:SecretVersion"
}

#AwsSecurityGroup: {
	base.#Resource
	type: "aws:ec2:SecurityGroup"
	properties: tags: #QvsManagedLabel
}

#AwsSecurityGroupEgressRule: {
	base.#Resource
	type: "aws:vpc:SecurityGroupEgressRule"
	properties: tags: #QvsManagedLabel
}

#AwsSecurityGroupIngressRule: {
	base.#Resource
	type: "aws:vpc:SecurityGroupIngressRule"
	properties: tags: #QvsManagedLabel
}

#AwsSubnet: {
	base.#Resource
	type: "aws:ec2:Subnet"
	properties: tags: #QvsManagedLabel
}

#AwsVpc: {
	base.#Resource
	type: "aws:ec2:Vpc"
	properties: tags: #QvsManagedLabel
}

#AwsWafIpSet: {
	base.#Resource
	type: "aws:wafv2:IpSet"
	properties: tags: #QvsManagedLabel
}

#AwsWafWebAcl: {
	base.#Resource
	type: "aws:wafv2:WebAcl"
	properties: tags: #QvsManagedLabel
}

#AwsWafWebAclAssociation: {
	base.#Resource
	type: "aws:wafv2:WebAclAssociation"
}

#AwsWafWebAclLoggingConfiguration: {
	base.#Resource
	type: "aws:wafv2:WebAclLoggingConfiguration"
}

#AwsCloudWatchLogDeliverySource: {
	base.#Resource
	type: "aws:cloudwatch:LogDeliverySource"
}

#AwsCloudWatchLogDelivery: {
	base.#Resource
	type: "aws:cloudwatch:LogDelivery"
}
#AwsCloudWatchLogGroup: {
	base.#Resource
	type: "aws:cloudwatch:LogGroup"
	properties: tags: #QvsManagedLabel
}
#AwsCloudWatchLogDeliveryDestination: {
	base.#Resource
	type: "aws:cloudwatch:LogDeliveryDestination"
	properties: tags: #QvsManagedLabel
}
