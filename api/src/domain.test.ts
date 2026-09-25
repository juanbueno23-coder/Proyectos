import {test} from 'node:test';import {strict as assert} from 'node:assert';import {memberSchema,userSchema} from './domain.js';
test('miembro exige nombre y correo válido',()=>{assert.equal(memberSchema.safeParse({first_name:'',last_name:'Pérez',email:'bad'}).success,false);assert.equal(memberSchema.safeParse({first_name:'Ana',last_name:'Pérez',email:'ana@example.org'}).success,true)});
test('contraseña inicial robusta y nombre limitado',()=>{assert.equal(userSchema.safeParse({username:'admin',password:'short',role_id:1}).success,false);assert.equal(userSchema.safeParse({username:'a',password:'larga y de más de doce',role_id:1}).success,false)});

test('nueva familia y campos opcionales vacíos normalizados',()=>{assert.equal(memberSchema.safeParse({first_name:'Ana',last_name:'Pérez',new_family:true,email:null,cedula:null}).success,true);assert.equal(memberSchema.safeParse({first_name:'Ana',last_name:'Pérez',new_family:true,family_code:'F-0001'}).success,false)});
