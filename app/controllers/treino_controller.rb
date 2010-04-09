class TreinoController < ApplicationController
  before_filter :require_login

  
  DECIMOS_EM_1_SEGUNDO = 10
  SEGUNDOS_EM_1_MINUTO = 60
  METROS_EM_1_KILOMETRO = 1000
  
  def show_interval
    
    di = params[:data]['inicio(1i)'] + '-' + params[:data]['inicio(2i)'] + '-' + params[:data]['inicio(3i)']
    df = params[:data]['fim(1i)'] + '-' + params[:data]['fim(2i)'] + '-' + params[:data]['fim(3i)']
        
    if Date.parse(di) > Date.parse(df)
      data_inicio = Date.parse(df)
      data_fim = Date.parse(di)  
    else
      data_inicio = Date.parse(di)
      data_fim = Date.parse(df)
    end
    @treinos = treinos(@atleta, data_inicio.beginning_of_week, data_fim.end_of_week)
    @show = false
    @matrizDeTreinos = []
    @treinos.each do |t|
      puts t.date
      
    end
    @data = data_inicio
    
    tamanho = @treinos.size
    for i in 0 ... tamanho/7
      semana = []
      @diaInicialDaSemana = @data.beginning_of_week + i*7
      @diaFinalDaSemana = @diaInicialDaSemana + 6
      for j in 0 ... 7 
        if @treinos.first.date == @diaInicialDaSemana + j
          semana << @treinos.shift
        else
          semana << nil
        end  
      end
      @matrizDeTreinos << semana 
    end
  end

  def show_month
    
    #data = Date.parse(params[:data])
    @data = Date.strptime(params[:data],"%d/%m/%Y")
    @treinos = treinos(@atleta, @data.beginning_of_month, @data.end_of_month)
    @matrizDeTreinos = []
  
    tamanho = @treinos.size
    for i in 0 ... tamanho/7
      semana = []
      @diaInicialDaSemana = @data.beginning_of_month + i*7
      @diaFinalDaSemana = @diaInicialDaSemana + 6
      for j in 0 ... 7 
        if @treinos.first.date == @diaInicialDaSemana + j
          semana << @treinos.shift
        else
          semana << nil
        end  
      end
      @matrizDeTreinos << semana 
    end
    render 'show_interval'
  end
  

  def show_month_transpost
    #data = Date.parse(params[:data])
    @data = Date.strptime(params[:data],"%d/%m/%Y")
    @treinos = treinos(@atleta, @data.beginning_of_month, @data.end_of_month)
    @matrizDeTreinos = []
    
    tamanho = @treinos.size
    for i in 0 ... tamanho/7
      semana = []
      @diaInicialDaSemana = @data.beginning_of_month + i*7
      @diaFinalDaSemana = @diaInicialDaSemana + 6
      for j in 0 ... 7 
        if @treinos.first.date == @diaInicialDaSemana + j
          semana << @treinos.shift
        else
          semana << nil
        end  
      end
      @matrizDeTreinos << semana 
    end
    @diasDaSemana = %w[Segunda Terça Quarta Quinta Sexta Sábado Domingo]
    render 'show_interval_transpost'
  end
  
  def treinos
    atleta = Atleta.find(params[:atleta_id])
    data_inicial = Time.parse(params[:from]).at_beginning_of_week
    data_final = Time.parse(params[:to]).at_beginning_of_week
    filtro_treinos =  Treino.find(:all, :order => "date ASC", :conditions => [
      "atleta_id = :id AND date >= :begin AND date <= :end",
      { :id => atleta.id, :begin => data_inicial, :end => data_final}])
    if filtro_treinos.size <= ((data_final - data_inicial).to_i)
      for data in data_inicial .. data_final do
        t = Treino.new(:date => data)
        atleta.treinos << t
      end
      atleta.save
      filtro_treinos =  Treino.find(:all, :order => "date ASC", :conditions => [
        "atleta_id = :id AND date >= :begin AND date <= :end",
        { :id => atleta.id, :begin => data_inicial, :end => data_final}])
    end
      filtro_treinos =  Treino.find(:all, :order => "date ASC", :conditions => [
            "atleta_id = :id AND date >= :begin AND date <= :end",
             { :id => atleta.id, :begin => data_inicial, :end => data_final}])
    filtro_treinos
  end
  
  def treino_atleta
    #verificação de atleta <-> treinador
    
    data = params[:data]
    if data.nil?
      data = Date.current 
    else
      data = Date.strptime(params[:data],"%d/%m/%Y")
    end
    @treinos = treinos
  end
  
  def change_week
   
    data = Date.strptime(params[:data],"%d/%m/%Y")
    @treinos = treinos(@atleta, data.beginning_of_week, data.end_of_week)
    redirect_to :action => 'treino_atleta', :atleta_id => params[:atleta_id], :data => data
  end
  
  def update_observation
    treino_id = params[:treino][:treino_id]
    treino = Treino.find(treino_id)
    atleta_id = treino.atleta_id
    treino.observacao = params[:treino][:observacao]
    treino.save
    redirect_to :action => 'treino_atleta', :atleta_id => atleta_id, :data => params[:data]
  end
  
  def update_commentary
    treino_id = params[:treino][:treino_id]
    treino = Treino.find(treino_id)
    atleta_id = treino.atleta_id
    treino.comentario = params[:treino][:comentario]
    treino.save
    redirect_to :action => 'treino_atleta', :atleta_id => atleta_id, :data => params[:data]
  end
  
  #refactorar este metodo, especialmente o seguinte:  :atleta_id  => params[:atleta_id]
  def cadastra_treino
    params[:treino].each do |id, new|
      Treino.find(id).update_attributes new
    end
    redirect_to :action => 'treino_atleta', :atleta_id => params[:atleta_id], :data => params[:data]
  end
 
  def calcula_ritmo  
    distancia = params[:tempo][:distancia].to_f
    intensidade = params[:tempo][:intensidade].to_f
    minutos = params[:tempo][:minutos].to_f
    segundos = params[:tempo][:segundos].to_f
    decimos = params[:tempo][:decimos].to_f
    
    if(distancia == 0.0 || intensidade == 0.0)
      error = 'Os campos distância e intensidade são obrigatórios'
    else
      tempo = (SEGUNDOS_EM_1_MINUTO * minutos * DECIMOS_EM_1_SEGUNDO) + (segundos * DECIMOS_EM_1_SEGUNDO) + decimos
      ritmo_em_decimos = (tempo) * (2 - (porcentagem_to_decimal intensidade))
      
      @ritmo_minutos = (ritmo_em_decimos / (SEGUNDOS_EM_1_MINUTO * DECIMOS_EM_1_SEGUNDO)).to_i;
      ritmo_em_decimos = ritmo_em_decimos - @ritmo_minutos * SEGUNDOS_EM_1_MINUTO * DECIMOS_EM_1_SEGUNDO;
      @ritmo_segundos = (ritmo_em_decimos / DECIMOS_EM_1_SEGUNDO).to_i
      ritmo_em_decimos = ritmo_em_decimos - @ritmo_segundos * DECIMOS_EM_1_SEGUNDO
      @ritmo_decimos = ritmo_em_decimos.to_i
      
    end
    
    @distancia = distancia.to_i;
    @intensidade = intensidade.to_i;
    @minutos = minutos.to_i;
    @segundos = segundos.to_i;
    @decimos = decimos.to_i;
    
    if(error != nil)
      redirect_to :action => 'calcula_ritmo_inicial', :error1 => error
    end
    
  end  
  
  def calcula_ritmo_parcial
    
    distancia = params[:tempo][:distancia].to_f
    parcial = params[:tempo][:parcial].to_f
    minutos = params[:tempo][:minutos].to_f
    segundos = params[:tempo][:segundos].to_f
    decimos = params[:tempo][:decimos].to_f
    
    if(distancia == 0.0)
      error = 'O campos distância é obrigatório'
    else
      tempo = (SEGUNDOS_EM_1_MINUTO * minutos * DECIMOS_EM_1_SEGUNDO) + (segundos * DECIMOS_EM_1_SEGUNDO) + decimos
      
      ritmo_em_decimos = tempo * parcial / distancia
      
      @minutos  = minutos.to_i
      @segundos = segundos.to_i
      @decimos = decimos.to_i
      @distancia = distancia.to_i
      @parcial = parcial.to_i
      @ritmo_minutos = (ritmo_em_decimos / (SEGUNDOS_EM_1_MINUTO * DECIMOS_EM_1_SEGUNDO)).to_i;
      ritmo_em_decimos = ritmo_em_decimos - @ritmo_minutos * SEGUNDOS_EM_1_MINUTO * DECIMOS_EM_1_SEGUNDO;
      @ritmo_segundos = (ritmo_em_decimos / DECIMOS_EM_1_SEGUNDO).to_i
      ritmo_em_decimos = ritmo_em_decimos - @ritmo_segundos * DECIMOS_EM_1_SEGUNDO
      @ritmo_decimos = ritmo_em_decimos.to_i
    end
    
    if(error != nil)
      redirect_to :action => 'calcula_ritmo_inicial', :error2 => error
    end 
  end

  def porcentagem_to_decimal porcentagem
    porcentagem / 100
  end
  

  private :porcentagem_to_decimal
  
end
