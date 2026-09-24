import pg from 'pg';
import fs from 'node:fs';
export const db = new pg.Pool({connectionString:process.env.DATABASE_URL ?? 'postgres://iglesia@127.0.0.1:5432/iglesia',max:10,ssl:false});
export const audit = async(actor:string|null, action:string, entity:string, id:string|null=null, detail:object={}) => {await db.query('INSERT INTO audit(actor_id,action,entity,entity_id,detail) VALUES($1,$2,$3,$4,$5)',[actor,action,entity,id,JSON.stringify(detail)]);};
export const dataDir=()=>{const d=process.env.IGLESIA_DATA_DIR;if(!d) throw Error('IGLESIA_DATA_DIR obligatorio');fs.mkdirSync(d,{recursive:true});return d;};
