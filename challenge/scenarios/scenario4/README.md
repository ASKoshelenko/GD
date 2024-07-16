# Scenario: scenario4

**Size:** Medium

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create scenario4`

## Scenario Resources

- 1 VPC with:
	- EC2 x 1
- 1 Lambda Function
- 1 S3 Bucket

## Scenario Start(s)

1. IAM User "Scenario4_1_user"

## Scenario Goal(s)

Invoke the "cg-lambda-[ CloudGoat ID ]" Lambda function.

## Summary

Starting as the IAM user Scenario4_1_user, the attacker discovers they have ReadOnly permissions to a Lambda function, where hardcoded secrets lead them to an EC2 instance running a web application that is vulnerable to server-side request forgery (SSRF). After exploiting the vulnerable app and acquiring keys from the EC2 metadata service, the attacker gains access to a private S3 bucket with a set of keys that allow them to invoke the Lambda function and complete the scenario.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/3117f737-3290-48c6-b0bf-e122a305858d/image.png)

## Route Walkthrough - IAM User "Scenario4_1_user"

1. As the IAM user Scenario4_1_user, the attacker explores the AWS environment and discovers they can list Lambda functions in the account.
2. Within a Lambda function, the attacker finds AWS access keys belonging to a different user - the IAM user Scenario4_2_user.
3. Now operating as Scenario4_2_user, the attacker discovers an EC2 instance running a web application vulnerable to a SSRF vulnerability.
4. Exploiting the SSRF vulnerability via the `?url=...` parameter, the attacker is able to steal AWS keys from the EC2 metadata service.
5. Now using the keys from the EC2 instance, the attacker finds a private S3 bucket containing another set of AWS credentials for a more powerful user: Scenario4_3_user.
6. Now operating as Scenario4_3_user, with full-admin final privileges, the attacker can invoke the original Lambda function to complete the scenario.

A cheat sheet for this route is available [here](./cheat_sheet_scenario4_1_user.md).