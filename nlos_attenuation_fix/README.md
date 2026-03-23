# NLOS attenuation fix

Este parche suaviza la compensacion de atenuacion para que cumpla mejor el espiritu del guion: **mitigar parte** de la caida por distancia y foreshortening, sin introducir una inversion artificial tipo anillo brillante.

## Problema observado

La implementacion anterior aplicaba una compensacion demasiado agresiva. En `Z`, la version compensada podia terminar con el centro oscuro y un borde exterior muy brillante. Eso no parece una mejora fisica de la reconstruccion, sino una sobrecompensacion.

## Idea del cambio

En vez de invertir toda la atenuacion geometrica, usamos una compensacion **suave**:

- exponente de distancia menor
- exponente de coseno menor
- clamp del coseno minimo para evitar explosiones en angulos rasantes
- clamp del peso maximo para evitar que pocos voxels dominen la MIP

## Archivos

- `nlos_backprojection.m`: reemplazo drop-in con compensacion suave
- `section4_attenuation.m`: compara `without` vs `soft` y opcionalmente `full`

## Parametros recomendados

Para empezar:

```matlab
opts.compensateAttenuation = true;
opts.attenuationMode = 'soft';
opts.attenuationDistanceExponent = 1.0;
opts.attenuationCosineExponent = 0.5;
opts.attenuationCosineMin = 0.20;
opts.attenuationMaxWeight = 8.0;
```

## Interpretacion esperada

La version compensada deberia:

- mantener la geometria principal en la misma zona
- cambiar el contraste de forma moderada
- no convertir la reconstruccion en un disco oscuro con borde brillante

Si la version `soft` sigue empeorando el resultado, no conviene defender attenuation compensation como mejora en la memoria; mejor presentarla como experimento exploratorio.
