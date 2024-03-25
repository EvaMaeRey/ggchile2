chile_regiones <- chilemapas::generar_regiones()

geo_reference_chile_region <- chile_regiones |>
  dplyr::select(region_codigo = codigo_region) |>
  sf2stat:::sf_df_prep_for_stat(id_col_name = "region_codigo")

usethis::use_data(geo_reference_chile_region, overwrite = T)
