class Import
  attr_accessor :file_path, :model, :attributes, :verify_attribute, :type
  def initialize file_path, model, verify_attribute, data_type
    @file_path = file_path
    @model = model
    @verify_attribute = verify_attribute
    @data_type = data_type
  end

  def valid?
    File.exists?(@file_path) && (is_csv? || is_json?)
  end

  def save!
    if is_csv?
      save_from_csv
    elsif is_json?
      save_from_json
    end
  end

  private
  def find_columns
    Settings.import.to_hash.detect{|key, _| key.to_s == @model.to_s.downcase}[1]
  end

  def is_csv?
    Settings.import.file_types.csv.include?(File.extname(@file_path)) &&
      csv_data_type_valid?
  end

  def is_json?
    Settings.import.file_types.json == File.extname(@file_path)
  end

  def csv_data_type_valid?
    csv_headers = Set.new CSV.open(@file_path, "r"){|csv| csv.first}
    model_attributes = Set.new model.send(:new).attributes.keys
    if model.send :const_defined?, :CSV_REJECT_ATTRIBUTES
      model_attributes -= Set.new model::CSV_REJECT_ATTRIBUTES
    end

    model_attributes.subset? csv_headers
  end

  def save_from_csv
    header = CSV.open(@file_path, "r") {|csv| csv.first}

    if check_right_model header, @data_type
      CSV.foreach @file_path, {headers: :first_row} do |row|
        save_object get_object_attributes(row)
      end
      return true
    end
    return false
  end

  def save_from_json
    datas = JSON.parse(File.read(@file_path).gsub("\\", "").gsub "\n", "")
    header = datas.first

    if check_right_model header, @data_type
      datas.each {|data| save_object get_object_attributes(data)}
      return true
    end
    return false
  end

  def save_object model_attributes
    model_attributes.delete :id
    model_attributes.delete :category_id

    if @object = @model.send(:find_by,
      @verify_attribute => model_attributes[@verify_attribute])
      @object.send :update_attributes, model_attributes
    else
      @model.send :create, model_attributes
    end
  end

  def get_object_attributes data
    data = @model.send(:standardize_data_to_import, data) if @model.respond_to? :standardize_data_to_import
    model_attributes = {}
    find_columns.each {|key, val| model_attributes[key.to_sym] = data[key.to_s]}
    if @model.respond_to? :standardize_csv_data
      @model.send :standardize_csv_data, model_attributes
    else
      model_attributes
    end
  end

  def check_right_model header, data_type
    case data_type
    when Settings.data_types_import.employee
      header.include? Settings.collum_check_import.employee
    when Settings.data_types_import.group
      header.include? Settings.collum_check_import.group
    when Settings.data_types_import.team
      header.include? Settings.collum_check_import.team && Settings.collum_check_import.team_name
    when Settings.data_types_import.group_employee
      header.include?(Settings.collum_check_import.group_employee) ||
        header.include?(Settings.import.groupemployee.employee_id)
    end
  end
end
