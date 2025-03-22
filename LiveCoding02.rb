# Welcome to Sonic Pi

use_random_seed 95
use_bpm 100 # 100 or 60

######### 操作 #########
start = true  # 開始前はtrue,開始後はnilにする(調整用)

process = "AFGC"

chord_f     = nil
base_f      = nil
arpeggio_f  = nil # pattern演奏
arpeggio2_f = nil # 高速ランダム演奏
lead_f      = nil # リードチップ
piano_f     = nil # ピアノ
drums_f     = nil

# 演奏
scale_f     = nil # スケール演奏
base_root   = 1 # ベースをルートのみにする



######### 進行 #########
if process == "AFGC"
  chords = [:A,     :F,     :G,     :C].ring
  option = [:minor, :major, :major, :major].ring
  timing = [2,      2,      2,      2].ring
elsif process == "AFGC*2"
  chords = [:A,     :F,     :G,     :C,    :A,     :F,     :G,     :C].ring
  option = [:minor, :major, :major, :major,:minor, :major, :major, :major].ring
  timing = [1,      1,      1,      1,     1,      1,      1,      1].ring
elsif process == "FGCA"
  chords = [:F,     :G,     :C,     :A].ring
  option = [:major, :major, :major, :minor].ring
  timing = [2,      2,      2,      2].ring
elsif process == "FGCA*2"
  chords = [:F,     :G,     :C,     :A,    :F,     :G,     :C,     :A].ring
  option = [:major, :major, :major, :minor,:major, :major, :major, :minor].ring
  timing = [1,      1,      1,      1,     1,      1,      1,      1].ring
elsif process == "AGFGC"
  chords = [:A,     :G,     :F,     :G,     :C].ring
  option = [:minor, :major, :major, :major, :major].ring
  timing = [2,      2,      1,      1,      2].ring
end


######### 初期化 #########
idx = 0
continue_flag = true

######### idle #########
live_loop :idle do
  2.times do
    chords.size.times do
      sleep timing[idx]
      idx += 1
    end
  end
end

######### コード #########
live_loop :chord do
  # 初期化
  if start
    sleep 0.1
    start = false
  end
  # 演奏
  use_synth :blade
  if chord_f # 演奏
    2.times do
      chords.size.times do
        play chord(chords[idx], option[idx]), amp: 1.5
        sleep timing[idx]
      end
    end
  else       # 休止
    sleep 16
  end
  continue_flag = false
end

######### ベース #########
live_loop :base do
  if start
    sleep 0.1
  end
  use_synth :chipbass
  idx_base = 0
  if base_f
    # 演奏
    2.times do
      chords.size.times do
        2.times do
          if base_root
            base_node = chord(chords[idx_base], option[idx_base])[0] - 12
          else
            base_node = chord(chords[idx_base], option[idx_base]).choose - 12
          end
          play base_node, amp: 0.5
          sleep timing[idx_base]/2.0
        end
        idx_base += 1
      end
    end
  else
    # 休止
    sleep 16
  end
end

######### アルペジオ #########
live_loop :arpeggio do
  if start
    sleep 0.1
  end
  # sync :base
  use_synth :fm
  # 演奏
  if arpeggio_f
    16.times do
      play_pattern_timed chord(chords[idx], option[idx])+12, [0.25, 0.25, 0.5], amp: 0.15
    end
  else
    sleep 16
  end
end

######### アルペジオ2  #########
live_loop :arpeggio2 do
  if start
    sleep 0.1
  end
  play_time2 = 0
  if arpeggio2_f
    while play_time2 < 16
      use_synth :chipbass
      length3 = [0.125, 0.125, 0.125, 0.25, 0.25, 0.5].choose
      play chord(chords[idx], option[idx]).choose, sustain: length3/2.0, release: length3, amp: 0.4
      sleep length3
      play_time2 += length3
    end
  else
    sleep 16
  end
end


######### オンコード(リード) #########
live_loop :lead do
  if start
    sleep 0.1
  end
  use_synth :chiplead
  continue_flag = true
  if lead_f
    while continue_flag
      length2 = [0.25, 0.25, 0.25, 0.5, 0.5, 1].choose
      node_lead = chord(chords[idx], option[idx]).choose
      play node_lead, decay: 0.2, release: length2
      play node_lead-12, decay: 0.2, release: length2, amp: 0.5
      sleep length2
    end
  else
    sleep 16
  end
end

######### オンコード(ピアノ) #########
live_loop :piano do
  if start
    sleep 0.1
  end
  use_synth :piano
  sleep 0.25
  continue_flag = true
  if piano_f
    while continue_flag
      length2 = [0.25, 0.25, 0.25, 0.5, 0.75, 0.75].choose
      sleep length2
      play chord(chords[idx], option[idx]).choose+12, release: length2, amp: 2
    end
  else
    sleep 16
  end
end
########################

####### スケール ########
# ヨナ抜き音階
my_scale = [:C4, :G5, :A4, :C5, :D5, :E5, :G5, :G5, :A5, :C6]

# 8分音符と4分音符をランダムに奏でるメロディー
live_loop :scale do
  if start
    sleep 0.1
  end
  if scale_f
    continue_flag = true
    while continue_flag
      use_synth :tb303
      length = [0.25, 0.25, 0.25, 0.5, 0.5, 1].choose
      node = my_scale.choose
      play node, amp: 0.5, release: length, amp: 1.3
      play node-12, amp: 0.5, release: length, amp: 0.5
      sleep length
    end
  else
    sleep 16
  end
end


######## ドラム #########
# 4ビート　パターン2(バスドラム二連打)
live_loop :four_beat_2 do
  if start
    sleep 0.1
  end
  if drums_f
    sample :drum_cymbal_hard, amp: 2
    8.times do
      sample :drum_cymbal_closed
      sample :drum_bass_hard
      sleep 0.5
      sample :drum_cymbal_closed
      sample :drum_snare_hard
      sleep 0.5
      sample :drum_cymbal_closed
      sample :drum_bass_hard
      sleep 0.25
      sample :drum_bass_hard
      sleep 0.25
      sample :drum_cymbal_closed
      sample :drum_snare_hard
      sleep 0.5
    end
  else
    sleep 16
  end
end
########################