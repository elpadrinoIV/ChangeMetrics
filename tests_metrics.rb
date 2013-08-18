#!/usr/bin/env ruby

require 'set'

# obtenog todos los hashes, el primero es el mas nuevo, el último el más viejo
hashes = `git log --pretty=format:"%H"`.split

# hashes que corresponden a cambios que no aportan a lo que se busca, verificado
# a mano (por ej: cambio en una linea agregado un año en el copyright)
hashes_a_ignorar = Set.new ["c1e4c47555cea326a6d3c93185c90a3df2d13b84",
	"ba03fe1917ae022427607c4270e643ccd78ec118",
	"3bec390e6f8e9e341149b7d060551a92b93d3154",
	"0a7a350f082f787f0e534f5ae75937dd2d91d0b9"]

# cuenta para cada commit, cuantas pruebas unitarias se cambiaron
pruebas_unitarias_cambiadas_en_cada_commit = Array.new

# cuenta cuantas veces se cambiaron 0 UT, 1 UT, etc en un commit
contador_pruebas_unitarias_por_commit = Hash.new

# uso reverse para recorrer en orden cronológico
hashes.reverse.each do |hash|
	hash.chomp!

	if hashes_a_ignorar.include? hash
		# este commit no me interesa
		next
	end

	# obtengo archivos que cambiaron
	archivos_cambiados = `git diff --name-status #{hash}^ #{hash}`.split("\n")

	pruebas_unitarias_cambiadas = 0

	# cuento, para este commit, todas las pruebas unitarias que cambiaron
	archivos_cambiados.each do |archivo_cambiado|
		archivo_cambiado.chomp!

		# para determinar si cambio una prueba unitaria, me fijo en los archivos
		# que terminen en Test.java y que hayan sido modificados
		if (/^M\s*src\/.+Test\.java$/.match(archivo_cambiado))
			pruebas_unitarias_cambiadas += 1
		end
	end

	if contador_pruebas_unitarias_por_commit.has_key?(pruebas_unitarias_cambiadas)
		contador_pruebas_unitarias_por_commit[pruebas_unitarias_cambiadas] += 1
	else
		contador_pruebas_unitarias_por_commit[pruebas_unitarias_cambiadas] = 1
	end

	pruebas_unitarias_cambiadas_en_cada_commit << pruebas_unitarias_cambiadas
end

############### IMPRIMIR DATOS ###############

min_pruebas_unitarias_cambiadas = pruebas_unitarias_cambiadas_en_cada_commit.min
max_pruebas_unitarias_cambiadas = pruebas_unitarias_cambiadas_en_cada_commit.max
suma_total = pruebas_unitarias_cambiadas_en_cada_commit.reduce(:+)
cantidad_commits = pruebas_unitarias_cambiadas_en_cada_commit.count
avg_pruebas_unitarias_cambiadas = suma_total.to_f / cantidad_commits.to_f

puts "MIN: #{min_pruebas_unitarias_cambiadas}"
puts "MAX: #{max_pruebas_unitarias_cambiadas}"
puts "AVG: #{avg_pruebas_unitarias_cambiadas}"

File.open('pruebas_unitarias_cambiadas_en_cada_commit.dat', 'w') do |archivo|
	numero_commit = 0
	pruebas_unitarias_cambiadas_en_cada_commit.each do |ut_cambiadas|
		numero_commit += 1
		archivo.puts("#{numero_commit}\t#{ut_cambiadas}")
	end
end

File.open('contador_pruebas_unitarias_por_commit.dat', 'w') do |archivo|
	contador_pruebas_unitarias_por_commit.sort.each do |clave, valor|
		archivo.puts "#{clave}\t#{valor}"
	end
end
