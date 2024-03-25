
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ggsomewhere

<!-- badges: start -->

<!-- badges: end -->

The goal of ggsomewhere (and it’s github repository) is to provide tools
for building spatial ggplot2 extensions.

The approach makes use of ggplot2’s sf plotting capabilities, the
sf2stat package to prepare reference data for use inside a stat\_\* or
geom\_\* layer, and the readme2pkg package functions for managing
functions from a readme and working with template functions included in
the readme.

## Fully worked example…

How you’d use sf2stat to build functionality with scope, region type,
and location name. When using the code templates for this north carolina
county example, we’ll be replacing ‘scope’, ‘region’, and ‘locations’ as
follows

  - ‘scope’ -\> ‘northcarolina’
  - ‘region’ -\> ‘county’
  - ‘locations’ -\> a vector of region names

Let’s see how we might recreate the functionality in the ggnorthcarolina
package using some templates in this readme.

In the example, the scope of the package is ‘northcarolina’. The region
of interest is ‘county’, and the location names that we are using are
the county names.

## 

``` r
devtools::create(".")
```

## Step 00. prep reference data

### Create

``` r
usethis::use_data_raw()
```

## Preparation

The reference data should have just the id columns and the geometry.
Then it should be named similar to this:

geo\_reference\_northcarolina\_county

Where ‘northcarolina’ is is the character string that will replace
‘scope’ when using the code templates, and ‘county’ is the character
string that will replace region in the

``` r
chile_regiones <- chilemapas::generar_regiones()


geo_reference_chile_region <- chile_regiones |>
  dplyr::select(region_codigo = codigo_region) |>
  sf2stat:::sf_df_prep_for_stat(id_col_name = "region_codigo")
#> Warning in st_point_on_surface.sfc(sf::st_zm(dplyr::pull(sf_df, geometry))):
#> st_point_on_surface may not give correct results for longitude/latitude data
#> Warning: The `x` argument of `as_tibble.matrix()` must have unique column names if
#> `.name_repair` is omitted as of tibble 2.0.0.
#> ℹ Using compatibility `.name_repair`.
#> ℹ The deprecated feature was likely used in the sf2stat package.
#>   Please report the issue to the authors.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

usethis::use_data(geo_reference_chile_region, overwrite = T)
#> ✔ Setting active project to '/Users/evangelinereynolds/Google Drive/r_packages/ggchile2'
#> ✔ Saving 'geo_reference_chile_region' to 'data/geo_reference_chile_region.rda'
#> • Document your data (see 'https://r-pkgs.org/data.html')
```

``` r
readme2pkg::chunk_to_dir("chile_geo_reference_prep", 
                         dir = "data-raw/")
```

## Use template to create `stat_county()` functionality

``` r
readme2pkg::chunk_variants_to_dir(chunk_name = "stat_region_template",
                                  file_name = "stat_region.R",
                                  replace1 = "scope",
                                  replacements1 = "chile",
                                  replace2 = "region",
                                  replacements2 = "region")
```

``` r
compute_panel_scope_region <- function(data, 
                                       scales, 
                                       keep_id = NULL, 
                                       drop_id = NULL, 
                                       stamp = FALSE){
  
  if(!stamp){data <- dplyr::inner_join(data, geo_reference_scope_region)}
  if( stamp){data <- geo_reference_scope_region }
  
  if(!is.null(keep_id)){ data <- dplyr::filter(data, id_col %in% keep_id) }
  if(!is.null(drop_id)){ data <- dplyr::filter(data, !(id_col %in% drop_id)) }
  
  data
  
}

# step 2
StatSfscoperegion <- ggplot2::ggproto(`_class` = "StatSfscoperegion",
                                `_inherit` = ggplot2::Stat,
                                # required_aes = c("fips|county_name"),
                                compute_panel = compute_panel_scope_region,
                               default_aes = ggplot2::aes(label = after_stat(id_col)))


stat_region <- function(
      mapping = NULL,
      data = NULL,
      geom = ggplot2::GeomSf,
      position = "identity",
      na.rm = FALSE,
      show.legend = NA,
      inherit.aes = TRUE,
      crs = "NAD27", # "NAD27", 5070, "WGS84", "NAD83", 4326 , 3857
      ...) {

  c(ggplot2::layer_sf(
              stat = StatSfscoperegion,  # proto object from step 2
              geom = geom,  # inherit other behavior
              data = data,
              mapping = mapping,
              position = position,
              show.legend = show.legend,
              inherit.aes = inherit.aes,
              params = rlang::list2(na.rm = na.rm, ...)
              ),
              
              coord_sf(crs = crs,
                       default_crs = sf::st_crs(crs),
                       datum = crs,
                       default = TRUE)
     )
  }
```

### test it out `stat_county()`

``` r
source("./R/stat_region.R")

library(ggplot2)
library(tidyverse)
#> ── Attaching core tidyverse packages ─────────────────── tidyverse 2.0.0.9000 ──
#> ✔ dplyr     1.1.0     ✔ readr     2.1.4
#> ✔ forcats   1.0.0     ✔ stringr   1.5.0
#> ✔ lubridate 1.9.2     ✔ tibble    3.2.1
#> ✔ purrr     1.0.1     ✔ tidyr     1.3.0
#> ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
#> ✖ dplyr::filter() masks stats::filter()
#> ✖ dplyr::lag()    masks stats::lag()
#> ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors

chile_regiones |>
  sf::st_drop_geometry() |>
  ggplot() +
  aes(region_codigo = codigo_region) +
  stat_region(linewidth = .05) + 
  aes(fill = codigo_region)
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

``` r

chilemapas::censo_2017_zonas |>
  count(region = stringr::str_extract(geocodigo, ".."), 
        edad, 
        wt = poblacion) %>% 
  group_by(region) %>% 
  mutate(prop = 100*n/sum(n)) ->
chile_regiones_edades

chile_regiones_edades |> 
  pivot_wider(names_from = edad, values_from  = prop, id_cols = region) |>
  janitor::clean_names() |>
  ggplot() + 
  aes(region_codigo = region) + 
  stat_region(linewidth = .02) + 
  aes(fill = x0_a_5) +
  scale_fill_viridis_c()
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-2.png)<!-- -->

``` r

last_plot() + 
  aes(fill = x6_a_14)
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-3.png)<!-- -->

``` r

last_plot() + 
  aes(fill = x15_a_64)
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-4.png)<!-- -->

``` r

last_plot() + 
  aes(fill = x65_y_mas)
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-5.png)<!-- -->

``` r
  
  
chilemapas::censo_2017_comunas |>
  count(region = stringr::str_extract(codigo_comuna, ".."), 
      sexo, wt = poblacion) |> 
  mutate(percent = n/sum(n), .by = region) |>
  filter(sexo == "mujer") |>
  ggplot() + 
  aes(region_codigo = region) + 
  stat_region(linewidth = .02) + 
  aes(fill = percent) + 
  scale_fill_viridis_c(option = "magma")
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-6-6.png)<!-- -->

## Use template to create useful derivitive functions

``` r
readme2pkg::chunk_variants_to_dir(chunk_name = "geom_region_template",
                                  file_name = "geom_region.R",
                                  replace1 = "region",
                                  replacements1 = "region")
```

``` r
geom_region <- stat_region
geom_region_label <- function(...){stat_region(geom = "text",...)}
stamp_region <- function(...){
  stat_region(stamp = T, 
              data = mtcars,
              aes(fill = NULL, color = NULL, label = NULL, 
                  fips = NULL, region_name = NULL), 
              ...)}
stamp_region_label <- function(...){
  stat_region(stamp = T, 
              geom = "text", 
              data = mtcars, 
              aes(fill = NULL, color = NULL,
                  fips = NULL, region_name = NULL), 
              ...)}
```

### try those out

``` r
source("./R/geom_region.R")

chile_regiones |>
  sf::st_drop_geometry() |>
  ggplot() +
  aes(region_codigo = codigo_region) +
  geom_region() + 
  geom_region_label(check_overlap = T,
                    color = "grey85") +
  aes(fill = codigo_region) 
#> Joining with `by = join_by(region_codigo)`
#> Joining with `by = join_by(region_codigo)`
```

![](README_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

``` r

ggplot() + 
  stamp_region() + 
  stamp_region_label(check_overlap = T)
```

![](README_files/figure-gfm/unnamed-chunk-8-2.png)<!-- -->

``` r

last_plot() + 
  stamp_region(keep_id = "05", fill = "darkred")
```

![](README_files/figure-gfm/unnamed-chunk-8-3.png)<!-- -->

## Use template to write convenience functions for each region

``` r
locations <- chile_regiones$codigo_region
locations_snake <- tolower(locations) |> 
  stringr::str_replace_all(" ", "_")

readme2pkg::chunk_variants_to_dir(chunk_name = "stamp_region_location", 
                                  file_name = "stamp_region_location.R",
                                  replace1 = "region",
                                  replacements1 = rep("region", length(locations)),
                              replace2 = "location",
                              replacements2 = locations_snake,
                              replace3 = "Location", 
                              replacements3 = locations)
```

``` r
#' Title
#'
#' @param ... 
#'
#' @return
#' @export
#'
#' @examples
stamp_region_location <- function(...){stamp_region(keep_id = 'Location', ...)}

#' Title
#'
#' @param ... 
#'
#' @return
#' @export
#'
#' @examples
stamp_region_label_location <- function(...){stamp_region_label(keep_id = 'Location', ...)}
```

### Try it out

``` r
source("./R/stamp_region_location.R")

ggplot() +
  stamp_region() + 
  stamp_region_05(fill = "darkred")
```

![](README_files/figure-gfm/last_test-1.png)<!-- -->

``` r

last_plot() + 
  stamp_region_label_05(color = "oldlace")
```

![](README_files/figure-gfm/last_test-2.png)<!-- -->
