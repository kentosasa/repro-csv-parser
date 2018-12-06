# lib
require "csv"
require "pry"

# const
BEGINNING_DAY = Date.strptime("2018-11-7","%Y-%m-%d")
PUSH_TYPES = ["新規", "継続"]
INPUT_DIR = "_INPUT/"
OUTPUT_DIR = "_OUTPUT/"

# methods
def group_by_day(table)
  data = Hash.new
  table.each do |row|
    tmp = data[row[1]] || Hash.new(0)
    tmp[:send] += row[2]
    tmp[:open] += row[3]
    tmp[:cvr] += row[4]
    data[row[1]] = tmp
  end
  return data
end


def group_by_week(day_hash)
  data = Hash.new
  start_date = BEGINNING_DAY
  end_date = start_date + 7
  while end_date < Date.today
    day_hash.each do |key, row|
      date = Date.strptime(key,"%Y-%m-%d")
      if start_date < date && end_date > date
        tmp = data[start_date] || Hash.new(0)
        tmp[:send] += row[:send]
        tmp[:open] += row[:open]
        tmp[:cvr] += row[:cvr]
        data[start_date] = tmp          
      end
    end

    # 翌週に更新
    start_date += 7
    end_date += 7  
  end
  return data
end


def cal_rate(weekly_hash)
  weekly_hash.each do |key, row|
    weekly_hash[key][:open_rate] = (row[:open].to_f / row[:send]).round(3)
    weekly_hash[key][:cvr_rate] = (row[:cvr].to_f / row[:send]).round(3)
  end
  return weekly_hash
end

def output_csv(data, type, push_type)
  CSV.open("#{push_type}#{OUTPUT_DIR}/result_#{type}.csv","w", encoding: "SJIS") do |table|
    # header の記入
    header = []
    start_date = BEGINNING_DAY
    end_date = start_date + 7
    while end_date < Date.today
      header.push(start_date)
      # 翌週に更新
      start_date += 7
      end_date += 7        
    end
    header.unshift("キャンペーン名")
    header.push("先週との差分")
    table << header

    # 各日付の値をとってくる
    data.each_with_index do |campaign, i|
      begin
        values = []
        before = 0
        diff = 0

        start_date = BEGINNING_DAY
        end_date = start_date + 7
        while end_date < Date.today
          key = start_date
          begin
            value = campaign[key][type.to_sym]
            values.push(value)
          rescue
            values.push(0)
          end
          # 翌週に更新
          start_date += 7
          end_date += 7  
        end
        values.unshift(campaign[:title].delete(".csv"))
        diff = values.last(2)[0] - values.last(2)[1]
        values.push(diff)
        table << values
      rescue => e
        puts "#{e.message}"
      end
    end    
  end
end


def init
  PUSH_TYPES.each do |push_type|
    data = []
    filenames = Dir.open("#{push_type}#{INPUT_DIR}",&:to_a)
    filenames.each do |name|
      begin
        table = CSV.table("#{push_type}#{INPUT_DIR}/#{name}")
        day_hash = group_by_day(table)
        week_hash = group_by_week(day_hash)
        rate_hash = cal_rate(week_hash)
        rate_hash[:title] = name
        data.push(rate_hash)  
      rescue => e
        puts e.message
      end
    end

    output_csv(data, "cvr_rate", push_type)
    output_csv(data, "open_rate", push_type)
    output_csv(data, "send", push_type)
  end
end

init
