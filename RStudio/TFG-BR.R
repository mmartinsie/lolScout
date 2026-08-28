########################################################################################
##                                                                                    ##
##    Proyecto: Análisis y predicción de series temporales aplicados                  ##
##                          al videojuego League of Legends                           ##
##                                                                                    ##
##    Autor: Manuel Martin Sierra                                                     ##
##    Fecha: Curso 2021/2022                                                          ##
##                                                                                    ##
########################################################################################
#Datos del banrate

# Navega por el sistema de archivos para elegir el fichero de datos y extraer la ruta
ruta <- file.choose()

# Directorio hasta llegar a la carpeta TFG
directorio <- substr(ruta, 1, nchar(ruta)-24)

# Fijar directorio de trabajo
setwd(directorio)

########------------------------------------------------------------------------########

# Instalacion de librerias necesarias para cargar script
install.packages("Rcpp")
install.packages("readxl") 
install.packages("e1071") 
install.packages("imputeTS") 
install.packages("cluster")
install.packages("pdc") 
install.packages("TSclust") 
install.packages("MASS") 
install.packages("forecast")
install.packages("tsfknn") 
install.packages("rnn") 
install.packages("ForecastComb") 
install.packages("xts") 
install.packages("dygraphs")

# Carga de librerias neceserias para realizar el trabajo
library(readxl) # Cargar datos
library(e1071) # Calcular algunos estadisticos
library(imputeTS) # Interpolacion
library(cluster) # Requerida por TSclust
library(pdc) # Requerida por TSclust
library(TSclust) # Calcular similitudes entre series temporales
library(MASS) # Escalado Multidimensional
library(forecast) # Prediccion con los modelos SARIMA y el metodo TBATS
library(tsfknn) # Prediccion con el metodo de los k vecinos mas proximos
library(rnn) # Prediccion con LSTM
library(ForecastComb) # Prediccion con combinaciones de predicciones
#install.packages("xts", repos="http://cloud.r-project.org")
library(xts) # Para aplicar antes de representar
library(dygraphs) # Representacion de series temporales
library(utils)

# Prediccion con el metodo de Redes Neuronales Autorregresivas
source('C:/Users/Manuel Martín Sierra/Documents/TFG/Series temporales/ARNN.R')


# Se fija la semilla para que el estudio sea reproducible
set.seed(2014)

########------------------------------------------------------------------------########
########                             Funciones auxiliares                       ########
########------------------------------------------------------------------------########
# Realiza la grafica donde se muestra la serie temporal
Grafica_Descripcion <- function(series, titulo){
  Actual <- xts(series,
                order.by = Fechas,
                frequency = 26)
  
  dygraph(Actual, titulo)
}

# Calcula el ECM y el EAM, a partir de los valores reales y los valores predichos de una
# serie temporal
Error_Prediccion <- function(valores_reales, valores_predichos){
  ECM <- sqrt(mean((valores_reales-valores_predichos)^2))
  EAM <- mean(abs(valores_reales-valores_predichos))
  
  list(ECM = ECM, EAM = EAM)
}

# Realiza la grafica donde se muestra la muestra de train, test y la prediccion
Grafica_Test <- function(producto, prediccion, titulo){
  Actual <- Series_Train_2[,producto]
  Test <- Series_Test_2[,producto]
  Predicted <- xts(prediccion,
                   order.by = Fechas_2,
                   frequency = 26)
  
  agrupacion_series <- cbind(Actual, Test, Predicted)
  colnames(agrupacion_series) <- c('Train', 'Test', 'Predicted')
  
  dygraph(agrupacion_series, titulo)
}

# Realiza la grafica donde se muestra la muestra de train y los valores internos
# ajustados por el modelo
Grafica_Train <- function(producto, prediccion, titulo){
  Actual <- Series_Train_2[,producto]
  Predicted <- xts(prediccion,
                   order.by = Fechas_1,
                   frequency = 26)
  
  agrupacion_series <- cbind(Actual, Predicted)
  colnames(agrupacion_series) <- c('Train', 'Predicted')
  
  dygraph(agrupacion_series, titulo)
}



########################################################################################
##                                                                                    ##
##                        CARGA, IMPUTACION Y ESTANDARIZACION                         ##
##                                                                                    ##
########################################################################################

########------------------------------------------------------------------------########
# Carga de datos desde fichero de Excel
datos <- read_excel(ruta, range = 'A1:EE131')
#datos <- read_excel(ruta, sheet = 1, guess_max = 1048576)

# Creacion de la serie temporal con dimension 4
Series_Originales <- ts(datos[,2:135], start = c(2017, 2), frequency = 26)

# Cantidad de datos en la serie
long_serie <- nrow(Series_Originales)

# Creacion de la fecha y conjunto de datos originales para la representacion
# Fechas <- seq(as.Date("2014-03-11"), length = long_serie, by = "2 weeks")
df_transpose <- data.frame(t(datos[-1]))
Fechas <- t(as.POSIXct(datos$date))
Series_Originales_2 <- xts(Series_Originales,
                           order.by = Fechas,
                           frequency = 26)

# Representacion de series temporales originales
Grafica_Descripcion(Series_Originales_2[,'jinx'], 'Serie Original (Jinx)')
#Grafica_Descripcion(Series_Originales_2[,'caitlyn'], 'Serie Original (Caytlin)')
#Grafica_Descripcion(Series_Originales_2[,'ashe'], 'Serie Original (Ashe)')
#Grafica_Descripcion(Series_Originales_2[,'lucian'], 'Serie Original (Lucian)')

# Copia de series para poder imputar a continuacion
Series_Imputadas <- Series_Originales

# Sustitucion de valores nulos por NA e imputacion con interpolacion
Series_Imputadas[Series_Imputadas == 0 ] <- NA
Series_Imputadas <- na_interpolation(Series_Imputadas, option = 'linear')

# Creacion del conjunto de datos imputados para la representacion
Series_Imputadas_2 <- xts(Series_Imputadas,
                          order.by = Fechas,
                          frequency = 26)

# Representacion de series temporales imputadas
Grafica_Descripcion(Series_Imputadas_2[,'jinx'], 'Serie Imputada (Jinx)')


########################################################################################
##                                                                                    ##
##                             ANALISIS DE CONGLOMERADOS                              ##
##                                                                                    ##
########################################################################################

# Para evitar que la escala de las series afecte a las distancias, se estandarizan las
# series temporales
Series_Estandarizadas <- scale(Series_Imputadas)

########------------------------------------------------------------------------########
########                  Creacion de las distancias entre series               ########
########------------------------------------------------------------------------########

# Creacion de data frame principal donde se recopila toda la informacion
Data_Frame_Principal <- data.frame(tipos = c('EUCL', 'COR', 'DTWARP', 'CORT'))

# Numero de filas para simplificar expresion
n_filas_Data_Frame_Principal <- nrow(Data_Frame_Principal)

## Distancia Euclidea (contempla proximidad)
Data_Frame_Principal$dist[[1]] <- diss(Series_Estandarizadas, METHOD = 'EUCL')

## Distancia Correlacion (contempla comportamiento)
Data_Frame_Principal$dist[[2]] <- diss(Series_Estandarizadas, METHOD = 'COR')

## Distancia DTWARP (contempla comportamiento)
Data_Frame_Principal$dist[[3]] <- diss(Series_Estandarizadas, METHOD = 'DTWARP')

## Distancia CORT (contempla comportamiento y proximidad)
Data_Frame_Principal$dist[[4]] <- diss(Series_Estandarizadas, METHOD = 'CORT')

# Impresion por pantalla de las distancias
options(max.print=1000000)
for (i in 1:n_filas_Data_Frame_Principal){
  print(paste('Distancia ',Data_Frame_Principal$tipos[[i]]))
  print(as.matrix(Data_Frame_Principal$dist[[i]]))
  
}

print(as.matrix(Data_Frame_Principal$dist[[1]]))



# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)


########------------------------------------------------------------------------########
########                          Escalado Multidimensional                     ########
########------------------------------------------------------------------------########

# Aplicacion del algoritmo de Escalado Multidimensional a cada una de las distancias 
for (i in 1:n_filas_Data_Frame_Principal){
  Data_Frame_Principal$Escalado[[i]] <- resultado_Euc <- isoMDS(Data_Frame_Principal$dist[[i]])
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)


# Creacion de pdf con representacion de puntos del Escalado Multidimensional
pdf(paste(directorio, 
          "2_Escalado_Multidimensional_Automatico.pdf",
          sep = ''), width = 8, height = 7)

for (i in 1:n_filas_Data_Frame_Principal){
  
  plot(Data_Frame_Principal$Escalado[[i]]$points[,1], 
       Data_Frame_Principal$Escalado[[i]]$points[,2], 
       cex = 2,
       pch = 16,
       t = 'n',
       bty = 'l',
       main = Data_Frame_Principal$tipos[i],
       xlab = '',
       ylab = '')
  text(Data_Frame_Principal$Escalado[[i]]$points[,1],
       Data_Frame_Principal$Escalado[[i]]$points[,2],
       labels = rownames(Data_Frame_Principal$Escalado[[i]]$points),
       cex = 0.8)
  
}

dev.off()

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)

# Creacion de png con representacion de puntos del Escalado Multidimensional
for (i in 1:n_filas_Data_Frame_Principal){
  
  png(paste(directorio,
            "2_Escalado_Multidimensional_Automatico_", 
            Data_Frame_Principal$tipos[[i]],
            ".png", sep = ""))
  
  plot(Data_Frame_Principal$Escalado[[i]]$points[,1], 
       Data_Frame_Principal$Escalado[[i]]$points[,2], 
       cex = 2,
       pch = 16,
       t = 'n',
       bty = 'l',
       main = Data_Frame_Principal$tipos[i],
       xlab = '',
       ylab = '')
  text(Data_Frame_Principal$Escalado[[i]]$points[,1],
       Data_Frame_Principal$Escalado[[i]]$points[,2],
       labels = rownames(Data_Frame_Principal$Escalado[[i]]$points),
       cex = 0.8)
  
  dev.off()
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)


########------------------------------------------------------------------------########
########                                 Dendrogramas                           ########
########------------------------------------------------------------------------########

# Creacion de los dendrogramas, para cada una de las distancias, segun encadenamiento
for (i in 1:n_filas_Data_Frame_Principal){
  
  # Encadenamiento simple
  Data_Frame_Principal$dend_sing[[i]] <- hclust(Data_Frame_Principal$dist[[i]], 
                                                method = 'single')
  
  # Encadenamiento ward
  Data_Frame_Principal$dend_ward[[i]] <- hclust(Data_Frame_Principal$dist[[i]], 
                                                method = 'ward.D')
  
  # Encadenamiento de medias
  Data_Frame_Principal$dend_aver[[i]] <- hclust(Data_Frame_Principal$dist[[i]], 
                                                method = 'average')
  
  # Encadenamiento de centroides
  Data_Frame_Principal$dend_cent[[i]] <- hclust(Data_Frame_Principal$dist[[i]], 
                                                method = 'centroid')
  
  # Encadenamiento completo
  Data_Frame_Principal$dend_comp[[i]] <- hclust(Data_Frame_Principal$dist[[i]], 
                                                method = 'complete')
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)


# Numero de encadenamientos usados
n_encadenamientos <- 5

# Creacion de pdf con representacion de dendrogramas, utilizando cada hoja por
# encadenamiento
pdf(paste(directorio,
          "4_Dendrogramas_1.pdf",
          sep = ''), width = 50, height = 20)

par(mfrow=c(1,4))

for (i in 4:(4+n_encadenamientos-1)){
  for (j in 1:n_filas_Data_Frame_Principal){
    plot(Data_Frame_Principal[[j,i]],
         main = paste('Distancia ', Data_Frame_Principal$tipos[[j]]))
  }
}

dev.off()

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i, j)


# Creacion de pdf con representacion de dendrogramas, utilizando cada hoja por
# distancia
pdf(paste(directorio,
          "4_Dendrogramas_2.pdf",
          sep = ''), width = 60, height = 10)

par(mfrow=c(1,5))

for (j in 1:n_filas_Data_Frame_Principal){
  for (i in 4:(4+n_encadenamientos-1)){
    plot(Data_Frame_Principal[[j,i]],
         main = paste('Distancia ', Data_Frame_Principal$tipos[[j]]))
    
  }
}

dev.off()

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i, j)

# Ejemplo de la memoria
pdf(paste(directorio,
          "4_Dendrogramas_3.pdf",
          sep = ''), width = 60, height = 10)

par(mfrow=c(1,5))


for (i in 4:(4+n_encadenamientos-1)){
  plot(Data_Frame_Principal[[4,i]],
       main = paste('Distancia ', Data_Frame_Principal$tipos[[4]]))
  
}

dev.off()

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i)
########------------------------------------------------------------------------########
########                 Dendrogramas con distintos encadenamientos             ########
########------------------------------------------------------------------------########

# Creacion de un pdf para cada distancia con representacion de dendrogramas segun cortes
for (i in 1:n_filas_Data_Frame_Principal){ # Itera distancias
  
  pdf(paste(directorio,
            '5_Distancia_', 
            Data_Frame_Principal$tipos[[i]],
            '.pdf',
            sep = ''), width = 60, height = 10)
  par(mfrow = c(1,5))
  
  for (corte in 2:5){ # Itera cantidad de cortes
    for (j in 4:(4+n_encadenamientos-1)){ # Itera los encadenamientos
      plot(Data_Frame_Principal[[i,j]], 
           cex = 0.7)
      rect.hclust(Data_Frame_Principal[[i,j]], 
                  k = corte, 
                  border = 'red')
    }
    
  }
  
  dev.off()
  
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(i, j)


# Dendograma con los cinco grupos para cada encadenamiento con distancia CORT
install.packages("ape")
library("ape")

colors = c("red", "blue", "green", "black", "orange")

n_encadenamientos=5

pdf(paste(directorio,
          'probando_5.pdf',
          sep = ''), width = 20, height = 10)

for (j in 4:(4+n_encadenamientos-1)){ # Itera los encadenamientos
  clus4 = cutree(Data_Frame_Principal[[4,j]], 5)
  plot(as.phylo(Data_Frame_Principal[[4,j]]),  type = "fan", tip.color = colors[clus4])
  
}

dev.off()

########------------------------------------------------------------------------########

# Tras revisar todas las alternativas y consultar con los profesinales que manejan estos
# datos, se toma la distancia CORT porque es la que compara, no solo la proximidad sino 
# tambien comportamiento (es mas completa que la euclidea, la correlacion y la DTWARP).
# 
# Con respecto al encadenamiento se toma el ward.D
# 
#
# La cantidad de grupos son 5, basandose en la similitud entre productos.

tipo_distancia <- 'CORT'
encadenamiento <- 'ward.D'
n_clusteres <- 5

# Se aplican los parametros determinados anteriormente para obtener el objeto distancia
# el dendograma y los grupos de productos fijados
distancia <- diss(Series_Estandarizadas, 
                  METHOD = tipo_distancia)

dend_CORT_cent <- hclust(distancia, 
                         method = encadenamiento)

clusters.variables <- cutree(dend_CORT_cent, n_clusteres)

########------------------------------------------------------------------------########
########                 Eleccion de representates de los clusters              ########
########------------------------------------------------------------------------########

# Para cada cluster, calculamos la serie media, es decir, la serie temporal cuyo valor
# en cada momento se obtiene de hacer medias de los valores en cada momento

# Lista con los representantes de cada uno de los clusters
representantes <- c(NULL)

# Se itera por cada grupo creado anteriormente
for (i in unique(clusters.variables)){
  
  # Conjunto de series del cluster clasificado en el grupo i
  cluster_aux <- Series_Imputadas[,clusters.variables == i]
  
  if (dim(as.matrix(cluster_aux))[2] == 1){
    # Si solo hay un serie en el cluster, se toma ella misma como representante
    representantes <- c(representantes,
                        names(clusters.variables)[clusters.variables == i])
    
  }else{
    # En caso contrario, se calcula la serie media entre todas las series del cluster i
    serie_media_aux <- ts(apply(cluster_aux, 1, mean), 
                          start = c(2017, 2),
                          frequency = 26)
    
    # Se aniade al resto de series del cluster y se calcula la distancia entre ellas
    serie_completa_aux <- ts.union(cluster_aux, serie_media_aux)
    distancia_aux <- as.matrix(diss(serie_completa_aux, METHOD = 'CORT'))
    
    # Se toma la ultima columna que es donde se ha situado la serie media del cluster
    num_var <- ncol(distancia_aux)
    vector_aux <- distancia_aux[1:(num_var-1),num_var]
    
    # Se toma como representante aquella que est? a menor distancia de la serie media
    # y se incorpora a la lista de representantes
    representantes <- c(representantes,
                        substr(names(which.min(vector_aux)),13,20))
  }
}
#Shaco->shaco jayce->zilean Morgana->alistar Taliyah->shen Rek\'Sai->illaoi
Grafica_Descripcion(Series_Imputadas[,'shaco'], 'Grupo Rojo (Shaco)')
Grafica_Descripcion(Series_Imputadas[,'zilean'], 'Grupo Azul (Zilean)')
Grafica_Descripcion(Series_Imputadas[,'alistar'], 'Grupo Verde (Alistar)')
Grafica_Descripcion(Series_Imputadas[,'shen'], 'Grupo Negro (Shen)')
Grafica_Descripcion(Series_Imputadas[,'illaoi'], 'Grupo Naranja (Illaoi)')


# Se borran las variables no necesarias para no sobrecargar memoria
rm(i, cluster_aux, serie_media_aux, distancia_aux, num_var, vector_aux)











































########################################################################################
##                                                                                    ##
##                               TECNICAS DE PREDICCION                               ##
##                                                                                    ##
########################################################################################

########------------------------------------------------------------------------########
########                Creacion de datos de entrenamiento y testeo             ########
########------------------------------------------------------------------------########

# Numero de datos a predecir
n_datos_test <- 7


# Creacion del conjunto de datos de entrenamiento
Series_Train <- ts(Series_Imputadas[1:(long_serie - n_datos_test),], 
                   start = c(2017, 2),
                   frequency = 26)

# Observacion - Si se cambia la cantidad de predicciones, tambien hay que cambiar la
# fecha en que se inicia la secuencia, ya que, de no hacerlo, los modelos salen mal
# Creacion del conjunto de datos de testeo
Series_Test <- ts(Series_Imputadas[(long_serie - (n_datos_test-1)):long_serie,],
                  start = c(2022, 2),
                  frequency = 26)


# Creacion del conjunto de datos de entrenamiento para la representacion
Fechas_1 <- seq(as.Date("2017-01-14"), length = long_serie - n_datos_test, by = "2 weeks")
Series_Train_2 <- xts(Series_Imputadas[1:(long_serie - n_datos_test),],
                      order.by = Fechas_1,
                      frequency = 26)

# Creacion del conjunto de datos de testeo para la representacion
# Observacion - Si se cambia la cantidad de predicciones, tambien hay que cambiar la
# fecha en que se inicia la secuencia, ya que, de no hacerlo, las graficas salen mal
Fechas_2 <- seq(as.Date("2021-09-23"), length = n_datos_test, by = "2 weeks")
Series_Test_2 <- xts(Series_Imputadas[(long_serie - (n_datos_test-1)):long_serie,],
                     order.by = Fechas_2,
                     frequency = 26)


########------------------------------------------------------------------------########
########                    Prediccion con distintos metodos                    ########
########------------------------------------------------------------------------########

# Ya que para calcular el error solo se necesitan las series representantes, se cogen
# solo esas, machacando la variable Series_Test anterior
Series_Test <- Series_Test[,representantes]

# Tambien creo las variables dummies MitadMes1 y MitadMes2 con un 1 la primera bisemana 
# del mes y un 0 la segunda y viceversa.
# Ademas de las variables dummies Mes01,..., Mes12 con un 1 en las dos bisemanas del
# mes correspondiente, excepto para Mes06 (julio) y Mes12 (Diciembre) donde aparecen 
# tres 1 seguidos. 
# Estos grupos de variables dummies se utilizan para modelizar la estacionalidad en el
# anio, en caso de ser necesario para el modelo

MitadMes1 <- c(rep(c(1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,0), times = 6))
MitadMes2 <- c(rep(c(0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1), times = 6))
Mes01 <- c(rep(c(1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes02 <- c(rep(c(0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes03 <- c(rep(c(0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes04 <- c(rep(c(0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes05 <- c(rep(c(0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes06 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes07 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes08 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0), times = 5))
Mes09 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0), times = 5))
Mes10 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0), times = 5))
Mes11 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0), times = 5))
Mes12 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1), times = 5))

# Creacion de data set con variables dummies para facilitar trabajo
dummies <- data.frame(MitadMes1, MitadMes2, Mes01, Mes02, Mes03, Mes04, Mes05, 
                      Mes06, Mes07, Mes08, Mes09, Mes10, Mes11, Mes12)

# Interacciones
for(j in 3:14){
  dummies[,j+12] <- dummies[,1] * dummies[,j]
}

for(j in 3:14){
  dummies[,j+24] <- dummies[,2] * dummies[,j]
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(j)


########------------------------------------------------------------------------########
# METODO 1 - MODELOS SARIMA (paquete forecast)

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_sarima <- c(NULL) 
pred_sarima <- c(NULL) 
error_pred_sarima <- c(NULL) 

for (repr in representantes){
  
  # Se entrena el modelo de prediccion
  mod_sarima_aux <- auto.arima(Series_Train[,repr], 
                               d = NA, 
                               D = NA, 
                               stationary = FALSE, 
                               seasonal = TRUE, 
                               ic = c("aicc", "aic", "bic"), 
                               test = c("kpss", "adf", "pp"), 
                               test.args = list(), 
                               seasonal.test = c("seas", "ocsb", "hegy", "ch"), 
                               seasonal.test.args = list())
  
  # Se predice con el modelo
  pred_sarima_aux <- forecast(mod_sarima_aux,
                              h = n_datos_test,
                              level=95)
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_sarima_aux$fitted[pred_sarima_aux$fitted < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_sarima_aux <- Error_Prediccion(Series_Test[,repr], 
                                            coredata(pred_sarima_aux$mean))
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_sarima <- c(mod_sarima, list(mod_sarima_aux))
  pred_sarima <- c(pred_sarima, list(pred_sarima_aux))
  error_pred_sarima <- c(error_pred_sarima, list(error_pred_sarima_aux))
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_sarima) <- representantes
names(pred_sarima) <- representantes
names(error_pred_sarima) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, mod_sarima_aux, pred_sarima_aux, error_pred_sarima_aux)


# Visualizacion de train con datos ajustados por modelo
Grafica_Train('zilean', mod_sarima[['zilean']]$fitted, "SARIMA (Zilean)")
Grafica_Train("illaoi", mod_sarima[["illaoi"]]$fitted, "SARIMA (Illaoi)")
Grafica_Train('shen', mod_sarima[['shen']]$fitted, "SARIMA (Shen)")
Grafica_Train('shaco', mod_sarima[['shaco']]$fitted, "SARIMA (Shaco)")
Grafica_Train('alistar', mod_sarima[['alistar']]$fitted, "SARIMA (Alistar)")

# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_sarima[['zilean']]$mean, "SARIMA (Zilean)")
Grafica_Test('illaoi', pred_sarima[['illaoi']]$mean, "SARIMA (Illaoi)")
Grafica_Test('shen', pred_sarima[['shen']]$mean, "SARIMA (Shen)")
Grafica_Test('shaco', pred_sarima[['shaco']]$mean, "SARIMA (Shaco)")
Grafica_Test('alistar', pred_sarima[['alistar']]$mean, "SARIMA (Alistar)")

#######------------------------------------------------------------------------########


########------------------------------------------------------------------------########
# METODO 2 - MODELO TBATS (Paquete forecast)

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_tbats <- c(NULL) 
pred_tbats <- c(NULL) 
error_pred_tbats <- c(NULL) 

for (repr in representantes){
  
  # Se entrena el modelo de prediccion
  mod_tbats_aux <- tbats(Series_Train[,repr])
  
  # Se predice con el modelo
  pred_tbats_aux <- forecast(mod_tbats_aux,
                             h = n_datos_test,
                             level=95)
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_tbats_aux$fitted[pred_tbats_aux$fitted < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_tbats_aux <- Error_Prediccion(Series_Test[,repr],
                                           coredata(pred_tbats_aux$mean))
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_tbats <- c(mod_tbats, list(mod_tbats_aux))
  pred_tbats <- c(pred_tbats, list(pred_tbats_aux))
  error_pred_tbats <- c(error_pred_tbats, list(error_pred_tbats_aux))
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_tbats) <- representantes
names(pred_tbats) <- representantes
names(error_pred_tbats) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, mod_tbats_aux, pred_tbats_aux, error_pred_tbats_aux)

# Visualizacion de train con datos ajustados por modelo
Grafica_Train('zilean', mod_tbats[['zilean']]$fitted.values, "TBATS (zilean)")
Grafica_Train('illaoi', mod_tbats[['illaoi']]$fitted.values, "TBATS (illaoi)")
Grafica_Train('shen', mod_tbats[['shen']]$fitted.values, "TBATS (shen)")
Grafica_Train('shaco', mod_tbats[['shaco']]$fitted.values, "TBATS (shaco)")
Grafica_Train('alistar', mod_tbats[['alistar']]$fitted.values, "TBATS (alistar)")

# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_tbats[['zilean']]$mean, "TBATS (Zilean)")
Grafica_Test('illaoi', pred_tbats[['illaoi']]$mean, "TBATS (Illaoi)")
Grafica_Test('shen', pred_tbats[['shen']]$mean, "TBATS (Shen)")
Grafica_Test('shaco', pred_tbats[['shaco']]$mean, "TBATS (Shaco)")
Grafica_Test('alistar', pred_tbats[['alistar']]$mean, "TBATS (Alistar)")

#######------------------------------------------------------------------------########

#######------------------------------------------------------------------------########
# METODO 3 - MODELO REDES NEURONALES AUTORREGRESIVAS (Paquete arnn)

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_arnn <- c(NULL)
pred_arnn <- c(NULL)
error_pred_arnn <- c(NULL)

for (repr in representantes){
  
  # Se entrena el modelo de prediccion
  mod_arnn_aux <- arnn(x = Series_Train[,repr],
                       lags = 1:n_datos_test,
                       H = 2)
  
  # Se predice con el modelo
  pred_arnn_aux <- forecast(mod_arnn_aux,
                            h = n_datos_test,
                            level = 90)
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_arnn_aux$mean[pred_arnn_aux$mean < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_arnn_aux <- Error_Prediccion(Series_Test[,repr],
                                          coredata(pred_arnn_aux$mean))
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_arnn <- c(mod_arnn, list(mod_arnn_aux))
  pred_arnn <- c(pred_arnn, list(pred_arnn_aux))
  error_pred_arnn <- c(error_pred_arnn, list(error_pred_arnn_aux))
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_arnn) <- representantes
names(pred_arnn) <- representantes
names(error_pred_arnn) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, mod_arnn_aux, pred_arnn_aux, error_pred_arnn_aux)

# Se le aniaden 7 NaN a la prediccion en los datos de train con el modelo para evitar
# error en la representacion
for (repr in representantes){
  mod_arnn[[repr]]$fitted  <- ts(c(NaN, NaN, NaN, NaN, NaN, NaN, NaN, 
                                   mod_arnn[[repr]]$fitted), 
                                 start = c(2017, 2), 
                                 frequency = 26)
}

# Visualizacion de train con datos ajustados por modelo
Grafica_Train('zilean', mod_arnn[['zilean']]$fitted, "ARNN (zilean)")
Grafica_Train('illaoi', mod_arnn[['illaoi']]$fitted, "ARNN (illaoi)")
Grafica_Train('shen', mod_arnn[['shen']]$fitted, "ARNN (shen)")
Grafica_Train('shaco', mod_arnn[['shaco']]$fitted, "ARNN (shaco)")
Grafica_Train('alistar', mod_arnn[['alistar']]$fitted, "ARNN (alistar)")

# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_arnn[['zilean']]$mean, "ARNN (Zilean)")
Grafica_Test('illaoi', pred_arnn[['illaoi']]$mean, "ARNN (Illaoi)")
Grafica_Test('shen', pred_arnn[['shen']]$mean, "ARNN (Shen)")
Grafica_Test('shaco', pred_arnn[['shaco']]$mean, "ARNN (Shaco)")
Grafica_Test('alistar', pred_arnn[['alistar']]$mean, "ARNN (Alistar)")
########------------------------------------------------------------------------########


########------------------------------------------------------------------------########
# METODO 4 - K VECINOS MAS PROXIMOS (Paquete tsfknn)

# 1. Metodo recursivo o iterativo

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_knn_rec <- c(NULL) 
pred_knn_rec <- c(NULL) 
error_pred_knn_rec <- c(NULL) 

for (repr in representantes){
  
  # Se entrena el modelo de prediccion
  mod_knn_rec_aux <- knn_forecasting(Series_Train[,repr],
                                     h = n_datos_test, # Predecir las futuras 7 bisemanas
                                     lags = 1:n_datos_test, 
                                     k = 12,
                                     msas = "recursive")
  
  # Se predice con el modelo
  pred_knn_rec_aux <- mod_knn_rec_aux$prediction
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_knn_rec_aux[pred_knn_rec_aux < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_knn_rec_aux <- Error_Prediccion(Series_Test[,repr],
                                             coredata(pred_knn_rec_aux))
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_knn_rec <- c(mod_knn_rec, list(mod_knn_rec_aux))
  pred_knn_rec <- c(pred_knn_rec, list(pred_knn_rec_aux))
  error_pred_knn_rec <- c(error_pred_knn_rec, list(error_pred_knn_rec_aux))
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_knn_rec) <- representantes
names(pred_knn_rec) <- representantes
names(error_pred_knn_rec) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, mod_knn_rec_aux, pred_knn_rec_aux, error_pred_knn_rec_aux)

# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_knn_rec[['zilean']], "k-NN Recursivo (Zilean)")
Grafica_Test('illaoi', pred_knn_rec[['illaoi']], "k-NN Recursivo (Illaoi)")
Grafica_Test('shen', pred_knn_rec[['shen']], "k-NN Recursivo (Shen)")
Grafica_Test('shaco', pred_knn_rec[['shaco']], "k-NN Recursivo (Shaco)")
Grafica_Test('alistar', pred_knn_rec[['alistar']], "k-NN Recursivo (Alistar)")

# Esquema de prediccion
# autoplot(mod_knn_rec[['Prod_01']], highlight = "neighbors", faceting = TRUE)

# 2. Metodo MIMO (entra multiple, salida multiple)

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_knn_mimo <- c(NULL) 
pred_knn_mimo <- c(NULL) 
error_pred_knn_mimo <- c(NULL) 

for (repr in representantes){
  
  # Se entrena el modelo de prediccion
  mod_knn_mimo_aux <- knn_forecasting(Series_Train[,repr],
                                      h = n_datos_test, # Predecir las futuras 7 bisemanas
                                      lags = 1:n_datos_test, 
                                      k = 12,
                                      msas = "MIMO")
  
  # Se predice con el modelo
  pred_knn_mimo_aux <- mod_knn_mimo_aux$prediction
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_knn_mimo_aux[pred_knn_mimo_aux < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_knn_mimo_aux <- Error_Prediccion(Series_Test[,repr],
                                              coredata(pred_knn_mimo_aux))
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_knn_mimo <- c(mod_knn_mimo, list(mod_knn_mimo_aux))
  pred_knn_mimo <- c(pred_knn_mimo, list(pred_knn_mimo_aux))
  error_pred_knn_mimo <- c(error_pred_knn_mimo, list(error_pred_knn_mimo_aux))
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_knn_mimo) <- representantes
names(pred_knn_mimo) <- representantes
names(error_pred_knn_mimo) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, mod_knn_mimo_aux, pred_knn_mimo_aux, error_pred_knn_mimo_aux)


# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_knn_mimo[['zilean']], "k-NN MIMO (Zilean)")
Grafica_Test('illaoi', pred_knn_mimo[['illaoi']], "k-NN MIMO (Illaoi)")
Grafica_Test('shen', pred_knn_mimo[['shen']], "k-NN MIMO (Shen)")
Grafica_Test('shaco', pred_knn_mimo[['shaco']], "k-NN MIMO (Shaco)")
Grafica_Test('alistar', pred_knn_mimo[['alistar']], "k-NN MIMO (Alistar)")

# Esquema de prediccion
# autoplot(mod_knn_mimo[['Prod_01']], highlight = "neighbors", faceting = TRUE)
########------------------------------------------------------------------------########


########------------------------------------------------------------------------########
# METODO 5 - MODELO MAQUINA VECTOR SOPORTE (Paquete e1071)
# Tambien creo las variables dummies MitadMes1 y MitadMes2 con un 1 la primera bisemana 
# del mes y un 0 la segunda y viceversa.
# Ademas de las variables dummies Mes01,..., Mes12 con un 1 en las dos bisemanas del
# mes correspondiente, excepto para Mes06 (julio) y Mes12 (Diciembre) donde aparecen 
# tres 1 seguidos. 
# Estos grupos de variables dummies se utilizan para modelizar la estacionalidad en el
# anio, en caso de ser necesario para el modelo

MitadMes1 <- c(rep(c(1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,0), times = 6))
MitadMes2 <- c(rep(c(0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1), times = 6))
Mes01 <- c(rep(c(1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes02 <- c(rep(c(0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes03 <- c(rep(c(0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes04 <- c(rep(c(0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 6))
Mes05 <- c(rep(c(0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes05 <- c(Mes05, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes06 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes06 <- c(Mes06,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes07 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0), times = 5))
Mes07 <- c(Mes07,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes08 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0), times = 5))
Mes08 <- c(Mes08,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes09 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0), times = 5))
Mes09 <- c(Mes09, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes10 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0), times = 5))
Mes10 <- c(Mes10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes11 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0), times = 5))
Mes11 <- c(Mes11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
Mes12 <- c(rep(c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1), times = 5))
Mes12 <- c(Mes12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

# Creacion de data set con variables dummies para facilitar trabajo
dummies <- data.frame(MitadMes1, MitadMes2, Mes01, Mes02, Mes03, Mes04, Mes05, 
                      Mes06, Mes07, Mes08, Mes09, Mes10, Mes11, Mes12)

# Interacciones
for(j in 3:14){
  dummies[,j+12] <- dummies[,1] * dummies[,j]
}

for(j in 3:14){
  dummies[,j+24] <- dummies[,2] * dummies[,j]
}

# Se borran las variables no necesarias para no sobrecargar memoria
rm(j)
# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
mod_svm <- c(NULL) 
pred_svm <- c(NULL) 
error_pred_svm <- c(NULL) 
for (repr in representantes){
  
  Prod <- Series_Imputadas[,repr]
  Tiempo <- 1:length(Prod)
  
  DF <- dummies
  DF$Prod <- Prod
  DF$Tiempo <- Tiempo
  DF$Lag1Prod <- c(NA, Prod[1:(long_serie-1)])
  # DF$Lag2Prod <- c(NA, NA, Prod[1:(long_serie-2)])
  
  DF$Med <-  c(NA, rollmean(Prod,
                            k = 2,
                            align = 'center'))
  
  DF_Train <- DF[1:(long_serie - n_datos_test),]
  DF_Test <- DF[(long_serie - (n_datos_test-1)):long_serie,]
  
  # Se entrena el modelo de prediccion (se deja el valor de gamma que calcula R por 
  # defecto, ya que aporta buenos resultados y se sube la penalizacion)
  mod_svm_aux <- svm(Prod ~.,
                     data = DF_Train,
                     type = 'eps-regression',
                     kernel = 'radial',
                     cost = 100)
  
  # Se a?ade a los datos del modelo las predicciones intramuestrales con el formato
  # de serie temporal adecuado para luego poder representarlo
  mod_svm_aux[[repr]]$fitted  <- ts(c(NaN, 
                                      mod_svm_aux[[repr]]$fitted), 
                                    start = c(2017, 2), 
                                    frequency = 26)
  
  # Se predice con el modelo
  pred_svm_aux <- predict(mod_svm_aux,
                          newdata = DF_Test)
  
  # Por el contexto del problema, las predicciones solamente pueden ser nulas o
  # positivas, asi que las negativas se cambian por cero
  pred_svm_aux[pred_svm_aux < 0] <- 0
  
  # Se calcula el ECM y el EAM
  error_pred_svm_aux <- Error_Prediccion(Series_Test[,repr],
                                         pred_svm_aux)
  
  # Se genera el conjunto de listas con los modelos, las predicciones y los errores
  mod_svm <- c(mod_svm, list(mod_svm_aux))
  pred_svm <- c(pred_svm, list(pred_svm_aux))
  error_pred_svm <- c(error_pred_svm, list(error_pred_svm_aux))
  
}

# Se asignan los nombres de los representantes al conjunto de modelos, predicciones
# y errores
names(mod_svm) <- representantes
names(pred_svm) <- representantes
names(error_pred_svm) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, Prod, Tiempo, DF, DF_Train, DF_Test, mod_svm_aux, pred_svm_aux, 
   error_pred_svm_aux)

# Se le a?aden 1 NaN a la prediccion en los datos de train con el modelo para evitar
# error en la representacion
for (repr in representantes){
  mod_svm[[repr]]$fitted  <- ts(c(NaN, 
                                  mod_svm[[repr]]$fitted), 
                                start = c(2017, 2), 
                                frequency = 26)
}

# Visualizacion de train con datos ajustados por modelo
Grafica_Train('zilean', mod_svm[['zilean']]$fitted, "SVM (zilean)")
Grafica_Train('illaoi', mod_svm[['illaoi']]$fitted, "SVM (illaoi)")
Grafica_Train('shen', mod_svm[['shen']]$fitted, "SVM (shen)")
Grafica_Train('shaco', mod_svm[['shaco']]$fitted, "SVM (shaco)")
Grafica_Train('alistar', mod_svm[['alistar']]$fitted, "SVM (alistar)")


# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_svm[['zilean']], "SVM (zilean)")
Grafica_Test('illaoi', pred_svm[['illaoi']], "SVM (illaoi)")
Grafica_Test('shen', pred_svm[['shen']], "SVM (shen)")
Grafica_Test('shaco', pred_svm[['shaco']], "SVM (shaco)")
Grafica_Test('alistar', pred_svm[['alistar']], "SVM (alistar)")

########------------------------------------------------------------------------########


########------------------------------------------------------------------------########
# METODO 6 - MODELO COMBINACION DE MODELOS (Paquete ForecastComb)

# Se comienza creando los elementos correspondientes para poder realizar la combinacion
# de predicciones
pred <- c(NULL)
pred_estruct <- c(NULL)

for (repr in representantes){
  # Agrupacion de las predicciones realizadas con todos los modelos
  pred_aux <- data.frame(pred_sarima[[repr]]$mean,
                         pred_tbats[[repr]]$mean,
                         pred_arnn[[repr]]$mean,
                         mod_knn_mimo[[repr]]$prediction,
                         mod_knn_rec[[repr]]$prediction)
  
  pred_aux <- ts(pred_aux,
                 start = c(2019, 14),
                 frequency = 26)
  
  # Para poder aplicar las funciones de la libreria, se necesita tener las series con
  # la estructura correcta
  pred_estruct_aux <- list(foreccomb(Series_Test[,repr], pred_aux))
  
  # Se genera el conjunto de listas con las series y estructuras necesarias
  pred <- c(pred, list(pred_aux))
  pred_estruct <- c(pred_estruct, pred_estruct_aux)
}

# Se asignan los nombres de los representantes al conjunto de predicciones y la es-
# tructura de foreccomb de las predicciones
names(pred) <- representantes
names(pred_estruct) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, pred_aux, pred_estruct_aux)

# 1. Metodo con la media aritmetica

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
pred_med_arit <- c(NULL) 
error_pred_med_arit <- c(NULL) 

for (repr in representantes){
  
  # Combinacion de predicciones
  pred_med_arit_aux <- comb_SA(pred_estruct[[repr]])
  
  # Se calcula el ECM y el EAM
  error_pred_med_arit_aux <- Error_Prediccion(Series_Test[,repr],
                                              coredata(pred_med_arit_aux$Fitted))
  
  # Se genera el conjunto de listas con las predicciones y los errores
  pred_med_arit <- c(pred_med_arit, list(pred_med_arit_aux))
  error_pred_med_arit <- c(error_pred_med_arit, list(error_pred_med_arit_aux))
  
}

# Se asignan los nombres de los representantes al conjunto de predicciones y errores
names(pred_med_arit) <- representantes
names(error_pred_med_arit) <- representantes


# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, pred_med_arit_aux, error_pred_med_arit_aux)


# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_med_arit[['zilean']]$Fitted, "Media Aritmetica (Zilean)")
Grafica_Test('illaoi', pred_med_arit[['illaoi']]$Fitted, "Media Aritmetica (Illaoi)")
Grafica_Test('shen', pred_med_arit[['shen']]$Fitted, "Media Aritmetica (Shen)")
Grafica_Test('shaco', pred_med_arit[['shaco']]$Fitted, "Media Aritmetica (Shaco)")
Grafica_Test('alistar', pred_med_arit[['alistar']]$Fitted, "Media Aritmetica (Alistar)")



# 2. Metodo con la media ponderada basada en las varianzas-covarianzas

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
pred_med_var <- c(NULL) 
error_pred_med_var <- c(NULL) 


for (repr in representantes){
  
  # Combinacion de predicciones
  pred_med_var_aux <- comb_BG(pred_estruct[[repr]])
  
  # Se calcula el ECM y el EAM
  error_pred_med_var_aux <- Error_Prediccion(Series_Test[,repr],
                                             coredata(pred_med_var_aux$Fitted))
  
  # Se genera el conjunto de listas con las predicciones y los errores
  pred_med_var <- c(pred_med_var, list(pred_med_var_aux))
  error_pred_med_var <- c(error_pred_med_var, list(error_pred_med_var_aux))
}


# Se asignan los nombres de los representantes al conjunto de predicciones y errores
names(pred_med_var) <- representantes
names(error_pred_med_var) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, pred_med_var_aux,error_pred_med_var_aux)

# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_med_var[['zilean']]$Fitted, "Media BG (zilean)")
Grafica_Test('illaoi', pred_med_var[['illaoi']]$Fitted, "Media BG (illaoi)")
Grafica_Test('shen', pred_med_var[['shen']]$Fitted, "Media BG (shen)")
Grafica_Test('shaco', pred_med_var[['shaco']]$Fitted, "Media BG (shaco)")
Grafica_Test('alistar', pred_med_var[['alistar']]$Fitted, "Media BG (alistar)")



# 3. Metodo con la media ponderada basada en la regresion

# Se crea el conjunto de listas donde se guardan los modelos, las predicciones y los
# errores para cada una de las variables
pred_med_CLS <- c(NULL) 
error_pred_med_CLS <- c(NULL) 

for (repr in representantes){
  
  # Combinacion de predicciones
  pred_med_CLS_aux <- comb_CLS(pred_estruct[[repr]])
  
  # Se calcula el ECM y el EAM
  error_pred_med_CLS_aux <- Error_Prediccion(Series_Test[,repr],
                                             coredata(pred_med_CLS_aux$Fitted))
  
  # Se genera el conjunto de listas con las predicciones y los errores
  pred_med_CLS <- c(pred_med_CLS, list(pred_med_CLS_aux))
  error_pred_med_CLS <- c(error_pred_med_CLS, list(error_pred_med_CLS_aux))
}

# Se asignan los nombres de los representantes al conjunto de predicciones y errores
names(pred_med_CLS) <- representantes
names(error_pred_med_CLS) <- representantes

# Se borran las variables no necesarias para no sobrecargar memoria
rm(repr, pred_med_CLS_aux, error_pred_med_CLS_aux)


# Visualizacion de train con test y prediccion
Grafica_Test('zilean', pred_med_CLS[['zilean']]$Fitted, "Media CLS (Zilean)")
Grafica_Test('illaoi', pred_med_CLS[['illaoi']]$Fitted, "Media CLS (Illaoi)")
Grafica_Test('shen', pred_med_CLS[['shen']]$Fitted, "Media CLS (Shen)")
Grafica_Test('shaco', pred_med_CLS[['shaco']]$Fitted, "Media CLS (Shaco)")
Grafica_Test('alistar', pred_med_CLS[['alistar']]$Fitted, "Media CLS (Alistar)")

print('Se ejecuto correctamente todo el codigo')

