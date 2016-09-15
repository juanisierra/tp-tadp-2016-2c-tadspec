require './test_initializer.rb'
require './resultados.rb'

class Mock
  attr_accessor :clase, :metodo, :cuerpo

  def restaurar
    clase.send(:define_method, metodo, cuerpo)
  end
end

class Metodo_espiado
  attr_accessor :objeto, :metodo, :parametros
end

class TADsPec

  @@resultados_asserts = []
  @@mocks = []
  @@metodos_espiados = []

  def self.is_suite? clase
    clase.instance_methods.any?{|me| is_test? me}
  end

  def self.is_test? metodo
    metodo.to_s.start_with?'testear_que_'
  end

  def self.obtener_lista_suites
    clases = []
    ObjectSpace.each_object(Class).each do |valor|
      clases = clases + [valor]
    end
    listaSuitsYSingletons = clases.select {|clase| TADsPec.is_suite? clase}
    listaSuits = listaSuitsYSingletons.select {|clase| !(clase.to_s.start_with? '#')} #sacamos a las singletons
    return listaSuits
  end

  def self.imprimir_lista_resultados
    @@resultados_asserts.each { |a| a.imprimir_resultado_test}
  end

  def self.mostrar_resultado
    cantidadCorridos = @@resultados_asserts.length
    pasados = @@resultados_asserts.select {|test| test.paso_test?}
    cantidadPasados= pasados.length
    fallados = @@resultados_asserts.select{|test| test.fallo_test?}
    cantidadFallados = fallados.length
    explotados = @@resultados_asserts.select{|test| test.exploto_test?}
    cantidadExplotados = explotados.length
    puts 'Se corrieron '+ cantidadCorridos.to_s+ ' tests:'
    puts 'Pasados: '+cantidadPasados.to_s
    puts 'Fallados: '+cantidadFallados.to_s
    puts 'Explotados: '+cantidadExplotados.to_s
    puts ' '
    puts 'Test Pasados con exito: '
    pasados.each{|test| puts 'Nombre: '+ test.nombreTest.to_s}
    puts ' '
    puts 'Test Fallidos: '
    fallados.each{|test|
      puts 'Nombre: ' + test.nombreTest.to_s
      puts ''
      puts 'Descripcion falla: '
      puts ' '
      test.mensaje_fallo
    }
    return
  end

  def self.agregar_asercion_actual booleano
    @@resultadoMetodo.add booleano
  end

  def self.agregar_metodo_espiado objeto, metodo, parametros
      met_espiado = Metodo_espiado.new
      met_espiado.objeto= objeto
      met_espiado.metodo= metodo
      met_espiado.parametros= parametros
      @@metodos_espiados = @@metodos_espiados+[met_espiado]
  end

  def self.obtener_metodos obj
    @@metodos_espiados.select{|metodo| metodo.objeto == obj}
  end

  def self.agregar_mock clase, metodo, cuerpo
    mockNvo = Mock.new
    mockNvo.clase= clase
    mockNvo.metodo= metodo
    mockNvo.cuerpo= cuerpo
    @@mocks = @@mocks+[mockNvo]
  end

  def self.borrar_mocks
    @@mocks.each {|mock| mock.restaurar}
    @@mocks = []
  end

  def self.transformar_metodos_testear args
    metodos = []
    args.each {|metodo| metodos = metodos + ['testear_que_' + metodo.to_s]}
    return metodos
  end

  def self.testear_metodo instancia, metodo
    @@resultadoMetodo = ResultadoTest.new
    @@resultadoMetodo.nombreTest= metodo
    instancia.send(metodo)
    @@resultados_asserts = @@resultados_asserts+[@@resultadoMetodo]
    TADsPec.borrar_mocks
    @@resultadoMetodo
  end

  def self.ejecutar_test_suite claseATestear
    metodos = claseATestear.new.methods
    metodos = metodos.select {|metodo| TADsPec.is_test? metodo}
    metodos.each {|metodo|
      instancia = claseATestear.new
      TADsPec.testear_metodo instancia, metodo }
  end

  def self.testear *args
    if(args[0] == nil)
      TADsPec.obtener_lista_suites.each {|suit| TADsPec.ejecutar_test_suite suit}
    elsif((TADsPec.is_suite? args[0]) && args[1] == nil)
      self.ejecutar_test_suite args[0]
    elsif((TADsPec.is_suite? args[0]) && args[1] != nil)
      metodos = TADsPec.transformar_metodos_testear args[1..-1]
      metodos.each{|metodo|
        instancia = args[0].new
        TADsPec.testear_metodo instancia, metodo}
    end
    #TADsPec.mostrar_resultado
    @@resultados_asserts = []
    return
  end
end

class Persona
  def viejo?
    @edad > 29
  end
  def set a
    @edad = a
  end
  def get
    @edad
  end
  def a
    puts 'chau'
  end
  def m var
    self.a
    puts var
  end
end

class Suit

  def testear_que_soy_yo
    7.deberia ser 7
    #7.deberia ser menor_a 6
    7.deberia ser uno_de_estos [1,2,3,7]
    8.deberia ser menor_a 11
    #7.deberia ser uno_de_estos [1,2,3]
  end
  def testear_que_so_vo
    a = Persona.new
    a.set 11
    a.deberia ser_viejo
    a.deberia tener_edad 30
    a.deberia tener_edad menor_a 90
    a.deberia tener_edad uno_de_estos [7, 22, "hola", 30]
    Object.deberia entender :new
    a.deberia entender :set
    #a = bloq { 7 / 0 }
    Persona.mockear(:m) do
      2
    end

    #a.deberia explotar_con ZeroDivisionError
  end
end

class Spy

  def testear_que_anda
    persona = Persona.new
    persona = espiar(persona)
    persona.m 'holis'
    persona.m 'holis'
    persona.deberia haber_recibido(:m).veces(2)
    #persona.deberia haber_recibido(:a)
  end
end