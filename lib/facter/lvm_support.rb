# lvm_support: true/nil
#   Whether there is LVM support (based on the presence of the "vgs" command)
Facter.add('lvm_support') do
  confine kernel: :linux

  setcode do
    vgdisplay = Facter::Util::Resolution.which('vgs')
    vgdisplay.nil? ? nil : true
  end
end

# lvm_vgs: [0-9]+
#   Number of VGs
Facter.add('lvm_vgs') do
  confine lvm_support: true

  setcode do
    if Facter.value(:lvm_support)
      vgs = Facter::Core::Execution.execute('vgs -o name --noheadings 2>/dev/null', timeout: 30)
    end

    if vgs.nil?
      0
    else
      vg_list = vgs.split

      # lvm_vg_[0-9]+
      #   VG name by index
      vg_list.each_with_index do |vg, i|
        Facter.add("lvm_vg_#{i}") { setcode { vg } }
        Facter.add("lvm_vg_#{vg}_pvs") do
          setcode do
            pvs = Facter::Core::Execution.execute("vgs -o pv_name #{vg} 2>/dev/null", timeout: 30)
            res = nil
            unless pvs.nil?
              res = pvs.split("\n").select { |l| l =~ %r{^\s+/} }.collect(&:strip).sort.join(',')
            end
            res
          end
        end
      end

      vg_list.length
    end
  end
end

# lvm_pvs: [0-9]+
#   Number of PVs
pv_list = []
Facter.add('lvm_pvs') do
  confine lvm_support: true

  setcode do
    if Facter.value(:lvm_support)
      pvs = Facter::Core::Execution.execute('pvs -o name --noheadings 2>/dev/null', timeout: 30)
    end

    if pvs.nil?
      0
    else
      pv_list = pvs.split

      # lvm_pv_[0-9]+
      #   PV name by index
      pv_list.each_with_index do |pv, i|
        Facter.add("lvm_pv_#{i}") { setcode { pv } }
      end

      pv_list.length
    end
  end
end
