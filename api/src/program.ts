import {z} from 'zod';
export const weekSchema=z.iso.date().refine(value=>new Date(`${value}T12:00:00Z`).getUTCDay()===1,'La semana inicia lunes');
export const cultSchema=z.object({day_offset:z.union([z.literal(1),z.literal(2),z.literal(3),z.literal(6)]),cult_name:z.string().trim().min(2).max(120),starts_at:z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),topic_word:z.string().trim().max(120).default(''),memory_instruction:z.string().trim().max(500).default(''),manual_override:z.boolean().default(false)});
export const itemSchema=z.object({position:z.number().int().positive(),activity:z.string().trim().min(2).max(120),member_id:z.number().int().positive(),responsible_name:z.literal('').default(''),starts_at:z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).nullable().optional(),minutes:z.number().int().min(1).max(240).nullable().optional(),topic:z.string().trim().max(250).default(''),scripture:z.string().trim().max(500).default(''),status:z.enum(['Pendiente','Notificado','Confirmado','Realizado','Cancelado']).default('Pendiente'),notes:z.string().trim().max(1000).default('')});
export const invitationSchema=z.object({event_date:z.iso.date(),event_time:z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).nullable().optional(),entity:z.string().trim().min(2).max(160),activity:z.string().trim().min(2).max(160),place:z.string().trim().max(200).default(''),contact:z.string().trim().max(120).default(''),phone:z.string().trim().max(40).default(''),modality:z.enum(['Presencial','Virtual','Mixta']).default('Presencial'),responsible:z.string().trim().max(120).default(''),status:z.enum(['Pendiente','Aceptada','Rechazada','Realizada']).default('Pendiente'),notes:z.string().trim().max(1000).default('')});
export function defaultCult(week:string,day:1|2|3|6,lastWednesday:'Damas'|'Caballeros'='Damas'){
 const name=day===1?'Escuela Bíblica':day===2?`Culto de ${lastWednesday==='Damas'?'Caballeros':'Damas'}`:day===3?'Culto de oración':'Culto dominical';
 return {day_offset:day,cult_name:name,starts_at:day===6?'10:00':'19:00',topic_word:'',memory_instruction:'',manual_override:false};
}
export function validateCult(existing:{day_offset:number;cult_name:string}[],cult:{day_offset:number;cult_name:string;manual_override:boolean}){
 if(existing.some(c=>c.day_offset===cult.day_offset&&c.cult_name!==cult.cult_name))throw Error('Solo un culto por día en la programación semanal');
 if(/damas/i.test(cult.cult_name)&&/caballeros/i.test(cult.cult_name))throw Error('Damas y Caballeros no pueden ser el mismo culto');
}
