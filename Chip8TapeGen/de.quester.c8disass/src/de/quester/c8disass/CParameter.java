package de.quester.c8disass;

import java.util.TreeMap;
import java.util.TreeSet;

public class CParameter {
	
	TreeMap<String, String> params = new TreeMap<>();
	TreeSet<String> cmds = new TreeSet<>();
	String args[];
	public CParameter(String[] args) {
		int p;
		this.args = args;
		for (String arg: args) {
			p = arg.indexOf('=');
			if (p == -1) p = arg.indexOf(':');
			if (p == -1) {
				cmds.add(arg);
			} else {
				String left, right;
				left = arg.substring(0,p);
				right = arg.substring(p+1);
				params.put(left, right);
			}
		}
	}
	
	public String getParam(String name) {
		return params.get(name);
	}
	
	public boolean isCmd(String name) {
		return cmds.contains(name);
	}

}
