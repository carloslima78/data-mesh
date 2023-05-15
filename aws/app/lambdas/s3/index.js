
// Função para integração com a S3 e SNS

'use strict'

// SDK da AWS para declarar o client
const AWS = require('aws-sdk')

// Dependência externa "Joi" para validação do Schema JSON
const Joi = require('joi')

// Declaração do client S3
const S3 = new AWS.S3()

// Declaração do client SNS
const SNS = new AWS.SNS()

// O Joi atribuindo os valores do JSON recebido em um schema para a tabela DynamoDB
const schema = Joi.object().keys({
    idpedido: Joi.string().required(),
    idcliente: Joi.string().required(),
    nome: Joi.string(),
    email: Joi.string(),
    telefone: Joi.string(),
    total: Joi.string()
})

// Recupera os dados presentes no arquivo no bucket S3
const getFileContent = async (S3, bucket, filename) => {
    const params = {
        Bucket: bucket,
        Key: filename
    }

    const file = await S3.getObject(params).promise()
    return JSON.parse(file.Body.toString('ascii'))
}

// Verifica se o item é válido utilizando o Schema
const isItemValid = (data) => {
    const isValid = schema.validate(data)
    return isValid.error === undefined
}

// Publica uma mensagem no tópico SNS com os dados presentes no Schema
const publish = async (SNS, payload) => {
    const { message, subject, topic } = payload
    const params = {
        Message: message,
        Subject: subject,
        TopicArn: topic
    }

    try {
        await SNS.publish(params).promise()
        console.log(`Message published: ${message}`)
        return true
    } catch (error) {
        console.error(error)
        return false
    }
}

exports.handler = async (event) => {
   
    // Se o debug estíver habilitado, escreve o log do evento
    if (process.env.DEBUG) {
        console.log(`Received event: ${JSON.stringify(event)}`)
    }

    // Verifica se existe um tópico definido e atribui seu ARN para a constante
    const topicArn = event.topicArn || process.env.TOPIC_ARN
    if (!topicArn) {
        throw new Error('No topic defined.')
    }

    // Realiza leitura dos dados presentes no arquivo 
    const { s3 } = event.Records[0]
    const content = await getFileContent(S3, s3.bucket.name, s3.object.key)
    let count = 0

    // Percorre os itens do arquivo
    for (let item of content) {

        // Verifica se cada item no arquivo é válido, retorna falso e loga um erro
        if (!isItemValid(item)) {
            console.log(`Invalid item found: ${JSON.stringify(item)}`)
            return false
        }

        // Publicação mensagem com os dados no tópico SNS
        await publish(SNS, {
            message: JSON.stringify(item),
            subject: 'Data from S3',
            topic: topicArn
        })

        count++
    }

    // Retorna a quantidade de mensagens que foram publicadas no tópico SNS
    return `Published ${count} messages to the Topic.`
}