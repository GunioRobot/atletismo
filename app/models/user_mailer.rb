class UserMailer < ActionMailer::Base
  EMAILPROJETO = "dontreply@atletismo.rodrigoflores.org"
  ASSUNTO_EMAIL = "Virtual Trainer - "
  ENDERECO_SITE = "http://atletismo.farok.net/"
  
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Por favor, ative sua conta'
    #@body[:url]  = ENDERECO + "activate/" + "#{user.activation_code}"
    @body = ENDERECO_SITE + "activate/" + "#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Sua conta foi ativada!'
    #@body[:url]  = ENDERECO_SITE
    @body  = ENDERECO_SITE
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject += "Redefinir senha"
    @body = ENDERECO_SITE + "reset_password/" + "#{user.password_reset_code}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = EMAILPROJETO
      @subject     = ASSUNTO_EMAIL
      @sent_on     = Time.now
      @body[:user] = user
    end
  
  
end
