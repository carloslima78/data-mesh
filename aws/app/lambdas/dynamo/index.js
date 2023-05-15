
// Função para integração com a tabela DynamoDB

'use strict'

// SDK da AWS para declarar o client
const AWS = require('aws-sdk')

// Declaração do client DinamoDB
const dynamo = new AWS.DynamoDB.DocumentClient()

const normalizeEvent = (event) => {
    
    // Caso o evento seja disparado pelo do SNS
    if (event.Records) {
        return {
            method: 'POST',
            data: JSON.parse(event.Records[0].Sns.Message),
            querystring: null
        }
    }

    // Caso o evento seja disparado pelo Api Gateway
    return {
        method: event.httpMethod,
        data: JSON.parse(event.body),
        querystring: event.queryStringParameters
    }
}

// Handler para realizar o CRUD no banco de dados
exports.handler = async (event) => {

    if (process.env.DEBUG) {
        console.log(`Received event: ${JSON.stringify(event)}`)
    }

    const table = event.table || process.env.TABLE
    if (!table) {
        throw new Error('No table name defined.')
    }

    const { method, data, querystring } = normalizeEvent(event)
    const params = { TableName: table }

    let res;
    let err;

    // De acordo com a ação desejada, será realizada a interação com o banco DynamoDB
    try {
        switch (method) {
            case 'GET':
                res = await dynamo.scan(params).promise()
                break;
            case 'POST':
                res = await dynamo.put({ ...params, Item: data }).promise()
                break;
            default:
                err = new Error(`Unsupported method "${method}"`)
        }
    } catch (error) {
        err = new Error(error.message)
    }

    return {
        statusCode: err ? 500 : 200,
        body: err ? err.message : JSON.stringify(res),
        headers: {
            'Content-Type': 'application/json',
        }
    }
}