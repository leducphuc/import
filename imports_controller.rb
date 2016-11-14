class ImportsController < ApplicationController
  before_action :init_message, only: :create

  def index
    if Settings.import.salary == params[:import]
      employee = Employee.find params[:salary][:employee_id]
      redirect_to [employee, :import_salaries]
    end

    @employees = Employee.select(:id, :display_name).order(:display_name)
  end

  def create
    if params[:type].present?
      params[:type].each_with_index do |data_type, index|
        import = Import.new "#{params[:file][index].tempfile.path.to_s}",
          find_model(data_type).constantize, find_verify_attribute(data_type), data_type
        if import.valid?
          import.save! ? @notice << data_type.gsub("_", " ").capitalize.pluralize :
            @alert << data_type.gsub("_", " ").capitalize.pluralize
        else
          @alert << data_type.gsub("_", " ").capitalize.pluralize
        end
      end
      redirect_to imports_path, notice: flash_message("import.success", @notice),
        alert: flash_message("import.alert", @alert)
    else
      redirect_to imports_path, alert: flash_message("import.no_select_file")
    end
  end

  private
  def find_model data_type
    data_type.split("_").each {|word| word.capitalize!}.join("")
  end

  def init_message
    @notice = Array.new
    @alert = Array.new
  end

  def find_verify_attribute model
    hash_data = Settings.import.data_types.detect do |data_type|
      data_type[:model] == model
    end

    hash_data[:verify_attribute].to_sym
  end
end
