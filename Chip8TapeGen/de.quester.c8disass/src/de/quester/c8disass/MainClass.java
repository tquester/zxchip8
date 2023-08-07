package de.quester.c8disass;

public class MainClass {

	
	public static void main(String[] args) {
		System.out.println("usuage in=chipfile out=textfile disass hex\n");
		
		CC8Decoder decoder = new CC8Decoder();
		CParameter para = new CParameter(args);
		String filename = para.getParam("in");
		String outfile = para.getParam("out");
		boolean disassFormat = para.isCmd("disass");
		boolean hex = para.isCmd("hex");
		decoder.start(filename, outfile, disassFormat, hex);

	}

}
