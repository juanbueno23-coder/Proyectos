# WhatsApp · estudio de viabilidad, 24-09-2026

Meta documenta una **Groups API** oficial, pero requiere una Official Business Account y su documentación describe la **creación** y gestión de grupos por el número empresarial. El límite documentado es de 8 participantes por grupo. No hay evidencia en esa documentación de que una aplicación pueda apropiarse del grupo personal existente «Iglesia Roca de Salvación». Por tanto, **no se promete ni se implementa** publicación automática en ese grupo. La viabilidad debe revisarse con el identificador y tipo de cuenta reales, tamaño del grupo y requisitos vigentes antes de implementar nada. Fuentes oficiales:

- [Groups API](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups)
- [Inicio: creación e invitación al grupo](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups/get-started)
- [Gestión de grupos](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups/reference)
- [Mensajes de grupos](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups/groups-messaging)
- [Webhooks de grupos](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups/webhooks)
- [Estados de mensaje](https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/messages/status)

**Alternativa segura para el grupo actual:** exportar texto formateado o imagen compatible, abrir el grupo manualmente y que una persona revise y envíe por WhatsApp. La aplicación registra «preparado»; no registra «enviado» ni «entregado» automáticamente. No usar SendKeys ni pegar a ciegas. Un enlace de compartir tampoco garantiza grupo destino ni pulsación final.

**Mensajes individuales:** estudiar WhatsApp Business Platform Cloud API por separado; requiere cuenta elegible, consentimiento/plantillas según tipo de conversación y conexión a Internet. El botón **Enviar** explícito iniciaría solicitudes solo entonces. Guardar un registro por destinatario e idempotencia por versión semanal; estados `preparado`, `enviado` (solicitud emitida), `aceptado` (ID del proveedor), `entregado` (acuse verificable específico), `fallido`. No confundir aceptación HTTP con entrega. Webhooks firmados y guardados con su ID actualizarían estados. La documentación de Meta sobre grupos y recibos contiene matices según tipo de mensaje y receptor; antes de afirmar entrega al grupo, probar la señal exacta de esa modalidad. La administración local seguirá funcionando offline; envío requiere red.
