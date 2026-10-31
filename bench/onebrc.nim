## The One Billion Row Challenge in Nanuq: the data generator and the query.
import std/[random, strutils, parsecsv, math]
import nanuq

proc onebrc*(path: string): LazyFrame =
  ## Min, mean and max temperature per weather station, sorted by station.
  scanCsv(path, separator = ';', hasHeader = false,
          schemaOverrides = {"column_2": Float64})
    .rename({"column_1": "station", "column_2": "measurement"})
    .groupBy(col("station"))
    .agg(
      col("measurement").min.alias("min"),
      col("measurement").mean.round(1).alias("mean"),
      col("measurement").max.alias("max"))
    .sort("station")

proc readStations*(path: string): seq[(string, float)] =
  ## The 413 weather stations of the challenge's generator, with their mean temperature.
  var p: CsvParser
  p.open(path, separator = ';')
  p.readHeaderRow()
  while p.readRow():
    result.add (p.row[0], parseFloat(p.row[1]))
  p.close()

proc generate*(stationsPath, path: string, rows: int, seed = 2024) =
  ## Writes `rows` lines `station;temperature`, like the challenge's
  ## CreateMeasurements.java: a random station, and a temperature drawn from a normal
  ## distribution around the station's mean (standard deviation 10), with one decimal.
  let stations = readStations(stationsPath)
  var r = initRand(seed)
  var f = open(path, fmWrite)
  defer: f.close()
  for _ in 0 ..< rows:
    let (name, mean) = stations[r.rand(stations.high)]
    var t = round(r.gauss(mean, 10.0) * 10.0) / 10.0
    if t == 0.0: t = 0.0  # no "-0.0"
    f.write name, ';', formatFloat(t, ffDecimal, 1), '\n'
