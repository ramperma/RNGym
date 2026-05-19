# Informe de referencia para una app de rutinas de gimnasio basada en bloques musculares y maquinaria

## Criterio de diseño del informe

Para una app de entrenamiento como la que describes, la forma más útil de organizar la lógica es separar cuatro capas: **bloques musculares**, **familias de máquinas**, **patrones de movimiento** y **reglas de prescripción**. Tomando como base a la entity["organization","Organización Mundial de la Salud","un health agency"], el entity["organization","American College of Sports Medicine","sports medicine society"], el entity["organization","NHS","uk health service"] y la entity["organization","American Heart Association","us heart health nonprofit"], el mínimo común para adultos sanos es trabajar todos los grandes grupos musculares **al menos 2 días por semana**; además, el NHS enumera esos grandes grupos como **piernas, caderas, espalda, abdomen, pecho, hombros y brazos**. citeturn22view0turn26search1turn20view1turn23view0

A nivel de programación, la guía del ACSM sigue siendo la referencia más útil para convertir evidencia en reglas de producto: para principiantes recomienda cargas equivalentes a **8-12 RM**, frecuencia de **2-3 días/semana**, y para hipertrofia un trabajo principalmente en **6-12 RM** con descansos de **1-2 minutos**; para fuerza máxima, recomienda un énfasis en cargas altas de **1-6 RM** con descansos de **3-5 minutos**. La revisión de la American Heart Association añade que, para salud general, **una serie de 8-12 repeticiones que fatigue el músculo** puede ser suficiente al inicio, y aconseja **dos días de descanso** antes de volver al mismo grupo muscular. citeturn10view0turn20view0

La literatura de hipertrofia también deja claro algo importante para tu backend: **la frecuencia importa, pero el volumen semanal importa más**. Los meta-análisis muestran que, cuando el volumen total se iguala, entrenar un músculo más veces por semana no siempre produce más hipertrofia por sí solo; aun así, repartir el trabajo en **2 o más estímulos semanales por músculo** sigue siendo la opción práctica mejor respaldada para casi todos los usuarios. Además, los programas con **más de 10 series semanales por grupo muscular** suelen superar a los de volumen muy bajo, y un rango práctico de **12-20 series por músculo** es una referencia habitual para adultos que ya no son principiantes. citeturn11search6turn11search12turn11search9turn16search0

Un detalle importante para no generar reglas engañosas en la app: la evidencia no suele prescribir “minutos exactos por músculo”, sino **días por semana, series, repeticiones, carga y descanso**. Por eso, más abajo incluyo dos cosas: la prescripción principal en términos fisiológicos y una **conversión operativa a minutos semanales** pensada para software y experiencia de usuario. citeturn22view0turn10view0turn11search9turn16search0

## Mapa completo de bloques musculares

Desde el punto de vista anatómico y funcional, el tren superior se organiza alrededor de la musculatura de hombro y brazo; el *core* incluye musculatura abdominal, glútea, cintura pélvica y paraspinal; la pared abdominal integra recto abdominal, oblicuos y transverso; la región glútea se compone principalmente de glúteo mayor, medio y menor; la pantorrilla superficial incluye gastrocnemio y sóleo; y la espalda combina musculatura superficial e intrínseca. Esa base anatómica encaja muy bien con la forma en que los gimnasios y los programas de fuerza dividen el cuerpo en bloques entrenables. citeturn8search0turn8search1turn8search20turn9search1turn9search6turn9search7turn9search9

| Bloque muscular | Músculos principales | Patrones de trabajo más útiles | Solapamientos que tu app debería contar |
|---|---|---|---|
| Pecho | Pectoral mayor, pectoral menor como accesorio, serrato en sinergia | Press horizontal, press inclinado, aperturas | Suma volumen indirecto en deltoide anterior y tríceps |
| Espalda vertical | Dorsal ancho, redondo mayor, trapecio inferior, romboides según variante | Pulldown, dominada asistida, pullover | Suma bíceps y deltoide posterior |
| Espalda horizontal | Romboides, trapecio medio/inferior, dorsal ancho, erectores como estabilización | Remo sentado, high row, T-bar row | Suma bíceps y deltoide posterior |
| Hombro | Deltoide anterior, medio y posterior; manguito rotador como estabilizador | Press vertical, elevación lateral, reverse fly | El pecho ya aporta mucho volumen al deltoide anterior |
| Bíceps y flexores del codo | Bíceps braquial, braquial, braquiorradial | Curl, curl en polea, curl guiado | La espalda vertical y horizontal ya aportan volumen indirecto |
| Tríceps | Tríceps braquial | Extensión de codo, fondos asistidos, press cerrado | El pecho y el hombro ya aportan volumen indirecto |
| Core anterior | Recto abdominal, transverso | Crunch cargado, anti-extensión, estabilidad | No todo el trabajo de core equivale al mismo estímulo |
| Core rotacional | Oblicuos interno y externo | Rotación, anti-rotación, oblicuos | Muy útil en perfiles deportivos y salud lumbar |
| Core posterior/lumbar | Erectores espinales, multifidus, cuadrado lumbar | Extensión lumbar, anti-flexión, bisagra controlada | No debe desaparecer aunque haya leg press o hack squat |
| Glúteos y cadera | Glúteo mayor, medio y menor | Hip thrust, empuje de cadera, abducción, extensión de cadera | Leg press, sentadilla y zancadas también los cargan |
| Cuádriceps | Recto femoral, vasto medial, lateral e intermedio | Extensión de rodilla, leg press, hack squat | La parte anterior de pierna suele compartir trabajo con glúteo |
| Isquiosurales | Bíceps femoral, semitendinoso, semimembranoso | Curl de pierna, bisagra de cadera, glute-ham | Se solapan con glúteo en patrones de extensión de cadera |
| Aductores | Aductor mayor, largo, corto, grácil | Aducción de cadera, trabajo medial de muslo | Mucha activación indirecta en sentadilla y prensa |
| Abductores | Glúteo medio/menor y tensor de la fascia lata | Abducción de cadera, cadera lateral | Muy relevantes para control pélvico |
| Gemelos y sóleo | Gastrocnemio y sóleo | Elevación de talones de pie o sentado | Suelen tolerar más frecuencia y más repeticiones |
| Tibial anterior y dorsiflexores | Tibial anterior y dorsiflexores asociados | Dorsiflexión, tibia dorsi | Grupo menos habitual, pero útil en rendimiento y prevención |
| Cuello y agarre | Flexores/extensores cervicales, trapecio superior, flexores/extensores de antebrazo | 4-way neck, shrug, gripper | Solo debería activarse en entornos avanzados o deportivos |

La tabla anterior sintetiza la agrupación anatómica y funcional que mejor traduce la evidencia a un gimnasio comercial y, sobre todo, a una base de datos de ejercicios. Para una app, esta vista funcional suele ser más útil que una lista puramente anatómica de músculos individuales. citeturn20view1turn8search1turn9search1turn9search6turn9search7turn9search9

## Familias de máquinas para tren superior

Para clasificar la maquinaria, este informe toma como referencia catálogos oficiales de entity["company","Life Fitness","fitness equipment maker"], entity["company","Hammer Strength","life fitness brand"] y entity["company","Matrix Fitness","fitness equipment maker"]. Los tres repiten, con pequeñas variaciones, las mismas grandes familias: **selectorizadas**, **plate-loaded**, **poleas/functional trainer**, **Smith guiada**, **asistidas** y **doble función**. A nivel de backend, esta clasificación es mucho más estable que guardar cada SKU por separado, y por eso conviene usarla como taxonomía principal. citeturn21view5turn20view2turn18search3turn13search0

| Familia de máquina | Qué incluye | Valor para tu app |
|---|---|---|
| Selectorizada | Carga por pila de pesas y recorrido guiado | Progresión muy fácil, ideal para perfiles novatos y generalistas |
| Plate-loaded | Carga con discos, muchas veces convergente o iso-lateral | Más orientada a fuerza, hipertrofia y sensación “atlética” |
| Poleas y functional trainer | Polea dual, poleas regulables, recorridos definidos por el usuario | Multi-bloque, alta versatilidad, útil para personalización por equipo disponible |
| Smith guiada | Barra guiada vertical o casi vertical | Sirve para pierna, pecho y hombro cuando se busca más estabilidad |
| Asistida | Assist dip/chin o equivalentes | Muy útil para tracción y empuje del tren superior en principiantes |
| Doble función | Ab/back, bíceps/tríceps, lat/low row, abductor/adductor | Ahorro de espacio y simplificación en gimnasios pequeños |
| Especializada | Gripper, 4-way neck, tibia dorsi, belt squat, glute drive | Conviene marcarla como “opcional/avanzada” en la base de datos |

### Empuje superior y hombros

La siguiente tabla resume las familias de máquinas más útiles para pecho, hombro y tríceps. Se apoya en gamas selectorizadas, plate-loaded y estaciones versátiles que aparecen de forma repetida en los catálogos comerciales consultados. citeturn20view2turn13search3turn18search3turn13search0turn18search4

| Bloque | Máquinas más habituales | Ejemplos de uso en rutinas |
|---|---|---|
| Pecho | Chest press, dual-axis chest press, press convergente, pec fly, multi-press, Smith, polea dual ajustable | Base de empuje horizontal; el *fly* aísla más y el press integra más tríceps y hombro |
| Hombro anterior y medio | Shoulder press, overhead press en Smith, lateral raise, multi-press | Útil para separar deltoide de pecho cuando el usuario ya tiene experiencia |
| Hombro posterior | Pec fly / rear deltoid, reverse fly, poleas altas | Muy útil para equilibrio escapular y compensar exceso de presses |
| Tríceps | Triceps extension, triceps press, fondos asistidos, polea para press-down | Conviene tratarlo como bloque de apoyo al empuje más que como núcleo de la sesión |

En la gama comercial consultada aparecen de forma explícita familias como **Chest Press**, **Dual Axis Chest Press**, **Shoulder Press**, **Lateral Raise**, **Pectoral Fly/Rear Deltoid**, **Triceps Extension/Press**, **Assist Dip Chin** y **Dual Adjustable Pulley**, lo que confirma que esas categorías son suficientemente estables como para modelarlas una sola vez y después mapear variantes por marca o gimnasio. citeturn20view2turn13search3turn13search0turn18search4

### Tracción superior y brazos

La tracción del tren superior merece una separación propia porque, en programación real, no solo entrena espalda: también suma volumen indirecto a bíceps, antebrazo y deltoide posterior. Si tu app no distingue ese solapamiento, tenderá a sobreprogramar brazos. citeturn10view0turn11search12

| Bloque | Máquinas más habituales | Ejemplos de uso en rutinas |
|---|---|---|
| Espalda vertical | Lat pulldown, dual-axis pulldown, front pulldown, fixed pulldown, assist dip/chin, pullover | Base para dorsal ancho y patrón de tracción vertical |
| Espalda horizontal | Row, seated row, high row, low row, T-bar row, chest/back combo | Base para romboides, trapecio medio y grosor de espalda |
| Brazos flexores | Biceps curl, seated biceps, curl en polea, curl unilateral guiado | Mejor como accesorio después de la tracción principal |
| Antebrazo y agarre | Gripper, curl/reverse curl con polea, trabajo de agarre en polea o barra | Grupo opcional; conviene activarlo por perfil deportivo o por déficit de agarre |

Los catálogos oficiales incluyen de forma reiterada **Pulldown**, **Dual Axis Pulldown**, **Row**, **Seated Row**, **High Row**, **T-Bar Row**, **Pullover**, **Biceps Curl** y **Gripper**. Esto respalda una estructura de datos donde “tracción vertical”, “tracción horizontal”, “flexión de codo” y “agarre” sean categorías distintas, aunque se solapen biomecánicamente. citeturn20view2turn18search3turn13search3turn6search1

## Familias de máquinas para core y tren inferior

### Core y zona lumbar

Los catálogos oficiales de fuerza comercial muestran que el *core* no se limita al clásico banco de abdominales. Las familias dominantes hoy son **abdominal crunch**, **abdominal advanced**, **rotary torso/torso rotation**, **back extension** y las máquinas de **doble función ab/low back**. Eso encaja bien con la literatura que entiende el *core* como un sistema que incluye musculatura abdominal, cadera y paraspinales, no solo el recto abdominal. citeturn20view2turn6search2turn7search2turn7search5turn8search1

| Bloque | Máquinas más habituales | Comentario de programación |
|---|---|---|
| Core anterior | Abdominal, abdominal advanced, crunch guiado, cable crunch | Mejor usarlo como flexión dinámica cargada, no como único trabajo de core |
| Core rotacional / oblicuos | Torso rotation, rotary torso, abdominal/oblique crunch | Útil si la app diferencia rotación y anti-rotación |
| Core posterior / lumbares | Back extension, ab/low back, extensiones guiadas | Muy útil para usuarios sedentarios y para equilibrio del tronco |

### Glúteos, cadera y piernas

En tren inferior, los catálogos oficiales son especialmente consistentes: **leg press**, **arc leg press**, **leg extension**, **leg curl**, **seated leg curl**, **glute**, **glute bridge**, **glute drive**, **hip abduction/adduction**, **calf extension**, **standing/seated calf**, **belt squat**, **hack squat**, **pendulum squat**, **tibia dorsi-flexion** y **Smith** aparecen repetidamente como familias comerciales. Esto permite cubrir prácticamente todo el cuerpo inferior con una taxonomía bastante limpia. citeturn20view2turn20view4turn19search13turn19search19turn7search0turn7search1turn7search4turn1search23turn1search5turn7search16turn7search19turn18search3turn18search4turn19search11

| Bloque | Máquinas más habituales | Comentario de programación |
|---|---|---|
| Glúteos / extensión de cadera | Glute, glute bridge, hip and glute, glute drive, rotary hip | Bloque clave para salud de cadera y fuerza general; muy buen candidato para perfiles por objetivo |
| Cadera lateral / medial | Hip abduction, hip adduction, hip abductor/adductor, sit/stand hip abductor, rotary hip | Muy útil para estabilidad pélvica y fuerza accesoria de pierna |
| Cuádriceps | Leg press, arc leg press, leg extension, hack squat, pendulum squat, belt squat, Smith squat/lunge | Núcleo de la fuerza del tren inferior en usuarios generalistas |
| Isquiosurales | Leg curl, seated leg curl, kneeling leg curl, assisted Nordic, glute-ham / reverse hyper | Conviene separar flexión de rodilla y extensión de cadera si la app afina mucho |
| Gemelos y sóleo | Calf extension, standing calf, seated calf, horizontal calf, calf press en leg press | Suele responder bien a más frecuencia y repeticiones medias-altas |
| Tibial anterior | Tibia dorsi-flexion, polea/tobillera para dorsiflexión | Grupo opcional, muy interesante para deporte y equilibrio muscular |
| Cuello y trapecio superior | 4-way neck, shrug | Solo recomendable como bloque avanzado o deportivo |

La presencia comercial de **leg press/calf press**, **leg extension**, **leg curl**, **glute bridge**, **glute drive**, **hip abduction/adduction**, **standing/seated calf**, **tibia dorsi-flexion** y **4-way neck** permite cubrir no solo los grupos “grandes”, sino también bloques menos comunes que sí aparecen en gimnasios orientados a rendimiento. Para tu app, lo sensato es marcarlos con un atributo tipo `availability_tier` para distinguir entre gimnasio básico, gimnasio completo y centro de alto rendimiento. citeturn21view5turn20view2turn18search3turn19search13turn7search4turn7search16turn7search19

## Frecuencia, tiempo semanal e intensidad

No existe una guía clínica seria que diga “pecho 52 minutos por semana” o “isquios 41 minutos”. Las guías públicas y las revisiones científicas prescriben sobre todo **frecuencia semanal, volumen, rango de repeticiones, carga y descanso**. Por eso, la mejor forma de diseñar tu producto es usar esas variables como fuente primaria y convertirlas después a minutos orientativos para UX, planificación y límites de sesión. citeturn22view0turn10view0turn11search9turn16search0

Como reglas generales para adultos sanos: el mínimo sanitario es **2 días por semana** para todos los grandes grupos musculares; en hipertrofia y fuerza recreativa, lo más práctico es programar **2-3 estímulos por grupo muscular**, reservando **3-4** para bloques que toleran bien más frecuencia, como glúteos, gemelos, *core* o abductores. Para fuerza máxima, cargas altas siguen siendo superiores; para hipertrofia, el crecimiento muscular puede lograrse con un abanico amplio de cargas si el esfuerzo es suficiente, aunque el rango medio de 6-12 repeticiones sigue siendo el más eficiente para la mayoría de usuarios de gimnasio. citeturn22view0turn20view0turn10view0turn11search11turn11search0turn16search2

### Zonas de intensidad recomendadas para la app

| Objetivo | Carga / intensidad práctica | Repeticiones por serie | Descanso orientativo | Uso recomendado |
|---|---|---|---|---|
| Salud e iniciación | Carga moderada que permita técnica estable y fatiga clara | 8-15 | 60-120 s | Usuarios novatos, readaptación general, alta adherencia |
| Hipertrofia general | Predominio de cargas moderadas | 6-12 como núcleo; también sirven rangos más altos | 60-120 s | La zona más versátil para la mayoría de usuarios de gimnasio |
| Fuerza máxima | Carga alta | 1-6 | 3-5 min | Bloques principales de pierna, pecho, espalda y press |
| Resistencia muscular local | Carga ligera a moderada | 15+ | <90 s | Core, gemelos, tibial anterior y accesorios |

Esta tabla resume la traducción práctica de las recomendaciones del ACSM: 8-12 RM para principiantes, 6-12 RM como énfasis de hipertrofia, 1-6 RM para fuerza y 40-60% de 1RM con más de 15 repeticiones para resistencia muscular local. La evidencia más reciente añade que la hipertrofia puede obtenerse también con cargas bajas si el esfuerzo es alto, mientras que la fuerza se maximiza mejor con cargas altas. citeturn10view0turn11search11turn11search0turn16search2

### Rangos operativos por grupo muscular

La columna de tiempo semanal que sigue es una **inferencia de producto** basada en rangos de series y descansos sugeridos por la evidencia. He supuesto, de forma deliberadamente conservadora, que una serie de aislamiento suele consumir unos **2-3 minutos** totales y una serie multiarticular pesada unos **3-5 minutos** contando ejecución, descanso y transición. No es una “verdad médica”; es un rango útil para motor de planificación, límites de sesión y recomendaciones automáticas. citeturn10view0turn11search9turn16search0

| Bloque muscular | Frecuencia práctica | Series directas por semana | Intensidad dominante | Tiempo semanal orientativo |
|---|---|---|---|---|
| Pecho | 2-3 | 8-16 | Principalmente 6-12 repeticiones; fases pesadas opcionales | 35-75 min |
| Espalda | 2-3 | 10-18 | Mezcla de tracción vertical y horizontal en 6-12 repeticiones | 45-90 min |
| Hombro | 2-3 | 8-14 | 8-15 repeticiones en presses y elevaciones | 30-60 min |
| Bíceps | 2-3 | 6-12 | 8-15 repeticiones | 20-40 min |
| Tríceps | 2-3 | 6-12 | 8-15 repeticiones | 20-40 min |
| Core anterior / rotacional | 2-4 | 6-12 | 10-20 repeticiones o series temporizadas | 15-35 min |
| Core posterior / lumbar | 1-3 | 4-10 | 10-15 repeticiones moderadas | 10-25 min |
| Glúteos | 2-4 | 8-20 | 6-15 repeticiones, con buena tolerancia a volumen alto | 30-75 min |
| Cuádriceps | 2-3 | 8-18 | 6-15 repeticiones | 35-80 min |
| Isquiosurales | 2-3 | 8-16 | 6-15 repeticiones | 30-70 min |
| Aductores / abductores | 2-4 | 6-12 | 10-20 repeticiones | 20-40 min |
| Gemelos y sóleo | 2-4 | 8-20 | 8-20 repeticiones | 20-50 min |
| Tibial anterior | 2-4 | 4-10 | 12-20 repeticiones | 10-25 min |
| Cuello / agarre | 1-3 | 4-8 | Moderada, muy controlada | 10-20 min |

La lectura correcta de esta tabla es la siguiente: el **mínimo útil** para la mayoría de usuarios principiantes está en la parte baja del rango; los usuarios intermedios suelen progresar mejor en la zona media; y el extremo alto debería reservarse para perfiles avanzados, muy tolerantes al volumen o con un objetivo claro de hipertrofia. Además, tu motor debería descontar **volumen indirecto**: si una sesión ya contiene mucho press de pecho, no tiene sentido asignar al deltoide anterior ni al tríceps el mismo volumen directo que a un usuario que casi no empuja. citeturn10view0turn11search12turn11search9turn16search0

## Traducción práctica al backend

Si quieres que el sistema sea escalable, no modeles “máquinas” como una lista plana. Modela al menos estas entidades: `muscle_block`, `movement_pattern`, `machine_family`, `machine_variant`, `exercise_template`, `prescription_rule` y `equipment_availability`. Así podrás reutilizar la misma lógica si el gimnasio tiene una chest press de una marca, una convergente de otra o una Smith como alternativa.

| Entidad | Campos mínimos recomendados | Por qué importa |
|---|---|---|
| `muscle_block` | `id`, `name`, `region`, `major_group_flag`, `primary_muscles[]`, `secondary_muscles[]` | Te permite separar pecho, espalda, glúteos, etc. |
| `movement_pattern` | `id`, `name`, `plane`, `joint_actions[]` | Diferencia press, tracción vertical, tracción horizontal, extensión de rodilla, etc. |
| `machine_family` | `id`, `name`, `category`, `guided_flag`, `unilateral_flag`, `space_tier` | Estabiliza la taxonomía entre gimnasios y marcas |
| `exercise_template` | `id`, `muscle_block_primary`, `muscle_block_secondary[]`, `machine_family_id`, `movement_pattern_id`, `difficulty_tier` | Es la unidad real que tu app asigna en rutina |
| `prescription_rule` | `goal`, `training_age`, `weekly_sets_min`, `weekly_sets_max`, `frequency_min`, `frequency_max`, `rep_min`, `rep_max`, `rest_sec_min`, `rest_sec_max` | Convierte evidencia en reglas automáticas |
| `volume_counter` | `direct_sets`, `indirect_sets`, `fatigue_weight` | Evita sobreprogramar hombro, tríceps y bíceps |
| `equipment_availability` | `gym_profile`, `machine_family_ids[]` | Permite adaptar la rutina al gimnasio real del usuario |
| `contraindication_profile` | `pathology_tag`, `movement_restrictions[]`, `preferred_alternatives[]` | Te servirá cuando añadas la capa clínica |

Para el motor de sesión, conviene además guardar una regla de orden: **grandes grupos antes de pequeños**, **multiarticulares antes de monoarticulares** y **trabajo de mayor intensidad antes del de menor intensidad**, porque ese es el orden que el ACSM recomienda para preservar rendimiento y calidad de ejecución. Si lo implementas así desde el principio, después te resultará mucho más fácil añadir variantes por patología, edad, nivel y material disponible sin rehacer el modelo de datos. citeturn10view0