# NLOS phasor fix

Este parche corrige la parte de phasor/Morlet para alinearla con el guion de la práctica:

1. `lambda_c` ya no se elige con el spacing de la pared a resolución completa.
   Ahora se calcula con el **spacing efectivo tras el downsampling** (`wallStride`).
2. Se impone `lambda_c >= 2 * spacing_efectivo`, como pide el enunciado.
3. `sigma` se barre con los valores recomendados en el guion:
   - `lambda_c / (2*log(2))`
   - `lambda_c`
   - `2*lambda_c`
4. Se guarda también una **baseline confocal LoG sin phasor** para comparar con justicia.
5. Se escriben checks en consola y en `phasor_summary.csv` para poder verificar:
   - `spacingEff`
   - `lambdaMin`
   - `wallStride`
   - `voxelRes`

## Archivos a reemplazar

Si ya estabas usando el esqueleto modular anterior, reemplaza estos archivos:

- `default_cfg.m`
- `section5_phasor_sweep.m`
- `morlet_filter_temporal.m`

Y añade este helper:

- `recommended_sigma_values.m`

## Comentario importante

La parte de backprojection confocal ya estaba usando, para datasets time-normalized,
`tof = d2 + d3`, y como en confocal `d3 = d2`, eso equivale a `2*distancia_pared_voxel`.
Por tanto, aquí no he cambiado `nlos_backprojection.m`.
