
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

// Schema para os itens do pedido
const itensPedidoSchema = Joi.object({
    idproduto: Joi.string().required(),
    nome: Joi.string().required(),
    valor: Joi.string().required()
  });

  // Schema para o meio de pagamento
const meioPagamentoSchema = Joi.object({
    idmeiopagamento: Joi.string().required(),
    nome: Joi.string().required()
  });

// Schema para o pedido
const pedidoSchema = Joi.object().keys({
    idpedido: Joi.string().required(),
    idcliente: Joi.string().required(),
    nome: Joi.string(),
    email: Joi.string(),
    telefone: Joi.string(),
    total: Joi.string(),
    produtos: Joi.array().items(itensPedidoSchema),
    meiopagamento: meioPagamentoSchema,
    status: Joi.string()
})

// Recupera o arquivo no bucket S3 
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
    const isValid = pedidoSchema.validate(data)
    return isValid.error === undefined
}

// Publica uma mensagem no tópico SNS com os dados presentes no schema do pedido
const publish = async (SNS, payload) => {
    const { message, subject, topic } = payload
    const params = {
        Message: message,
        Subject: subject,
        TopicArn: topic
    }

    try {
        await SNS.publish(params).promise()
        console.log(`Mensagem publicada: ${message}`)
        return true
    } catch (error) {
        console.error(error)
        return false
    }
}

exports.handler = async (event) => {
   
    // Se o debug estíver habilitado, escreve o log do evento
    if (process.env.DEBUG) {
        console.log(`Evento recebido: ${JSON.stringify(event)}`)
    }

    // Verifica se existe um tópico definido e atribui seu ARN para a constante
    const topicArn = event.topicArn || process.env.TOPIC_ARN
    if (!topicArn) {
        throw new Error('Não existe um tópico SNS definido.')
    }

    // Realiza leitura dos dados presentes no arquivo 
    const { s3 } = event.Records[0]
    const content = await getFileContent(S3, s3.bucket.name, s3.object.key)
    let count = 0

    // Percorre os itens do arquivo
    for (let item of content) {

        // Verifica se cada item no arquivo é válido, retorna falso e loga um erro
        if (!isItemValid(item)) {
            console.log(`Item inválido no JSON: ${JSON.stringify(item)}`)
            return false
        }
        else
        {
            console.log(`Evento recebido: ${JSON.stringify(item)}`)
        }

        // Publicação mensagem com os dados no tópico SNS
        await publish(SNS, {
            message: JSON.stringify(item),
            subject: 'Pedido carregado no S3',
            topic: topicArn
        })

        count++
    }

    // Retorna a quantidade de mensagens que foram publicadas no tópico SNS
    return `Foram publicadas ${count} mensagens no tópico SNS.`
}