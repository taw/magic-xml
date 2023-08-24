#!/usr/bin/env ruby

require "magic_xml"

def parts_of(parts, partid)
    res = []
    parts.each{|p|
        if p[:partof] == partid
            a = p.attrs.dup
            a.delete :partof
            res << xml(:part, a, parts_of(parts, p[:partid]))
        end
    }
    res
end

XML.parttree! {
    parts = XML.load('partlist.xml').children(:part)
    add! parts_of(parts, nil)
}
