#!/usr/bin/env python
import sys
import os
import getopt
import subprocess

class Args:
	def __init__(self):
		self.pair_align_file = ''
		self.ref_chr_list = ''
		self.tree = ''
		self.multiple_flag = False
		self.out_dir = os.getcwd()

def gen_multiz_multiple(args):
	if not os.path.exists(args.out_dir):
		try:
			os.mkdir(args.out_dir)
		except OSError:
			print >>sys.stderr, 'Error: can not mkdir "%s"' %(args.out_dir)
	chr_list = []
	fchr_list = open(args.ref_chr_list, 'r')
	for line in fchr_list:
		split = line[:-1].split()
		if split != []:
			chr_list.append(split[0])
			tmp_dir = args.out_dir + '/' + split[0]
			if not os.path.exists(tmp_dir):
				try:
					os.mkdir(tmp_dir)
				except OSError:
					print >>sys.stderr, 'Error: can not mkdir "%s"' %(tmp_dir)
		
	gen_shell_file = args.out_dir + '/' + 'gen_multiz.sh'
	fgen_multiz = open(gen_shell_file, 'w')
	
	fpair_align = open(args.pair_align_file, 'r')
	for line in fpair_align:
		tname, qname, pair_align = line[:-1].split()
		for chr in chr_list:
			output_dir = args.out_dir + '/' + chr
			pair_maf = pair_align + '/' + chr + '.maf'
			if not os.path.exists(pair_maf) or os.path.isdir(pair_maf):
				print >>sys.stderr, 'Error: %s is not found, maybe the naming style is wrong.' %(pair_maf)
				print_usage()
				sys.exit(1)
																	
			print >>fgen_multiz, 'ln -s %s/%s.maf %s/%s.%s.sing.maf' %(pair_align, chr, output_dir, tname, qname)
	
	
	run_shell_file = args.out_dir + '/' + 'run_multiz.sh'
	frun_multiz = open(run_shell_file, 'w')
	for chr in chr_list:
		output_dir = args.out_dir + '/' + chr
		print >>fgen_multiz, 'cd %s' %(output_dir)
		print >>fgen_multiz, '%s/roast - T=`pwd` E=%s "%s" *.*.maf %s.maf > run_multiz.sh' %(os.path.abspath(os.path.dirname(sys.argv[0])), tname, args.tree, chr)
		print >>fgen_multiz, 'cd -'
		print >>frun_multiz, 'cd %s; sh run_multiz.sh; cd - ;' %(output_dir) 
	fgen_multiz.close()
	frun_multiz.close()

	popen_ret = subprocess.Popen(['sh', gen_shell_file])
	popen_ret.wait()
	subprocess.Popen(['rm', gen_shell_file])
	
	
	
	
def gen_multiz(args):
	if not os.path.exists(args.out_dir):
		try:
			os.mkdir(args.out_dir)
		except OSError:
			print >>sys.stderr, 'Error: can not mkdir "%s"' %(args.out_dir)
	
	gen_shell_file = args.out_dir + '/' + 'gen_multiz.sh'
	fgen_multiz = open(gen_shell_file, 'w')
	fpair_align = open(args.pair_align_file, 'r')
	for line in fpair_align:
		tname, qname, pair_align = line[:-1].split()

		if pair_align[0] != '/':
			pair_align = os.path.abspath(os.path.dirname(args.pair_align_file)) + '/' + pair_align

		if not os.path.exists(pair_align) or os.path.isdir(pair_align):
			print >>sys.stderr, 'Error: %s is not found or it is a directory.' %(pair_align)
			print_usage()
			sys.exit(1)
			
		print >>fgen_multiz, 'ln -s %s %s/%s.%s.sing.maf' %(pair_align, args.out_dir, tname, qname)

	print >>fgen_multiz, 'cd %s' %(args.out_dir)
	print >>fgen_multiz, '%s/roast - T=`pwd` E=%s "%s" *.*.maf %s_ref.maf > run_multiz.sh' %(os.path.abspath(os.path.dirname(sys.argv[0])), tname, args.tree, tname)
	print >>fgen_multiz, 'cd -'
	
	fgen_multiz.close()

	popen_ret = subprocess.Popen(['sh', gen_shell_file])
	popen_ret.wait()
	subprocess.Popen(['rm', gen_shell_file])

def print_usage():
	#print 'TODO'
	usage = '''
Usage: python run_multiz.py [Options]

Options:
    --pair_align <path>     file containing pairwise alignment information.
                            row format:
                            species1 species2 [MAF file|MAF dir] 
    --multiple              set this to run a series of multiz, while the reference is split into several parts.
    --chr_list   <path>     file giving the sequence names of the reference, working with '--multiple'
    --tree       <tree>     tree in a modified Newick format
    --out        <dir>      output directory
    --help, -h              print this help
    
    Note:
    1. This program is just used to GENERATE jobs, NOT to RUN the alignment jobs.
    You have to run the jobs MANUALLY. It is a good habit to check the job scripts before submitting them.
	
	Example:
	1. 
	'''
	print >>sys.stderr, usage

def main():
	
	long_opts = ['help', 'pair_align=', 'multiple', 'chr_list=', 'tree=', 'out=']
	try:
		opts, args = getopt.getopt(sys.argv[1:], 'h', long_opts)
	except getopt.GetoptError, err:
		print >>sys.stderr, '\nError: ', str(err)
		print_usage()
		sys.exit(1)

	args = Args()
	for o, a in opts:
		#print o, a
		if o in ('--pair_align'):
			args.pair_align_file = a
		elif o in ('--multiple'):
			args.multiple_flag = True
		elif o in ('--chr_list'):
			args.ref_chr_list = a
		elif o in ('--tree'):
			args.tree = a
		elif o in ('--out'):
			args.out_dir = a
		elif o in ('-h', '--help'):
			print_usage()
			sys.exit(1)
		else:
			print >>stderr, 'Error: unknown option %s' %(o)			
	if args.pair_align_file == '' or args.tree == '':
		print >>sys.stderr, 'Error: you must provide the required files!'
		print_usage()
		sys.exit(1)
	if args.multiple_flag and args.ref_chr_list == '':
		print >>sys.stderr, 'Error: you must set "--chr_list" when you use "--multiple"!'
		print_usage()
		sys.exit(1)
	if args.multiple_flag:
		gen_multiz_multiple(args)
	else:
		if args.ref_chr_list != '':
			print >>sys.stderr, 'Warning: option "--chr_list" is ignored, it works with "--multiple"!'
		gen_multiz(args)

if __name__ == '__main__':
	main()

	
	
		
