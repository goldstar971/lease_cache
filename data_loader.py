#!/usr/bin/python3
import re
from scipy.stats.mstats import gmean
import numpy as np


PATH="/u/fliu14/Desktop/lease_cache/software/fpga_proxy/results/cache"
SINGLE_SCOPE=["atax","bicg","cholesky","doitgen","durbin","floyd-warshall","gemm","gesummv","gramschmidt","jacobi-1d","nussinov","seidel-2d","symm","syr2k","syrk","trisolv","trmm"]
def read_from_file(fname):
	content = list()
	with open(f"{fname}") as f:
		for line in f:
			line = line.rstrip()
			if line:
				content.append(line)
	return content


if __name__ == '__main__':
	experiments = ["CLAM", "SHEL","PRL","C-SHEL", "CARL"]
	# experiments = ["SHEL"]
	datasize = ["small", "medium", "large"]
	# datasize = ["small"]
	miss_reduction_distribution = {
		"<= 0%": {"small":0, "medium":0,"large":0},
		"<= 15%": {"small":0, "medium":0,"large":0},
		"<= 50%":{"small":0, "medium":0,"large":0},
		"<= 75%":{"small":0, "medium":0,"large":0},
		"> 75%":{"small":0, "medium":0,"large":0}
	}
	for input_size in datasize:
		f = f"{PATH}/results_{input_size}.txt"
		if input_size == "small":
			f = f"{PATH}/results.txt"
		print(f"read from {f} ...")
		content = read_from_file(f)
		baseline, test = dict(), dict()
		# read the baseline
		for line in content:
			restr = rf"..\/benchmarks\/SHEL_{input_size}\/(.*?)\/program,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,([0-9]+),[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,4$"
			if input_size == "small":
				restr = rf"..\/benchmarks\/SHEL\/(.*?)\/program,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,([0-9]+),[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,4$"
			if re.match(restr, line):
				search_result = re.findall(restr, line)[0]
				name, cache_miss_cnt = search_result[0],int(search_result[1])
				if name in SINGLE_SCOPE:
					continue
				# print(f"program: {name}, cache miss: {cache_miss_cnt}, cache_id {cache_id}")
				baseline[name] = cache_miss_cnt	
		max_reduction = 0.0
		for technique in experiments:
			for line in content:
				restr = rf"..\/benchmarks\/{technique}_{input_size}\/(.*?)\/program,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,(-?[0-9]+),[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,([4|8])$"
				if input_size == "small":
					restr = rf"..\/benchmarks\/{technique}\/(.*?)\/program,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,(-?[0-9]+),[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+,(4|8)$"
				if re.match(restr, line):
					search_result = re.findall(restr, line)[0]
					name, cache_miss_cnt, cache_id = search_result[0],int(search_result[1]), int(search_result[2])
					# print(f"{technique} {name} Miss count is {cache_miss_cnt}")
					if name in SINGLE_SCOPE:
						continue
					# print(f"program: {name}, cache miss: {cache_miss_cnt}, cache_id {cache_id}")
					if cache_id == 4:
						baseline[name] = cache_miss_cnt
					else:
						test[name] = cache_miss_cnt
			miss_reduction = []
			print(f"[{input_size}] {technique} vs PLRU")
			if len(baseline) > 0 and len(test) > 0:
				for name in baseline:
					reduction = (baseline[name] - test[name]) / baseline[name]
					if reduction <= 0:
						miss_reduction_distribution["<= 0%"][input_size] += 1
					elif reduction <= 0.15:
						miss_reduction_distribution["<= 15%"][input_size] += 1
					elif reduction <= 0.5:
						miss_reduction_distribution["<= 50%"][input_size] += 1
					elif reduction <= 0.75:
						miss_reduction_distribution["<= 75%"][input_size] += 1
					else:
						miss_reduction_distribution["> 75%"][input_size] += 1
					miss_reduction += [reduction]
					max_reduction = max(max_reduction, reduction)
					print(f"{name} reduce miss count: {reduction}")
				print(f"geomean: reduce miss count: {gmean(miss_reduction)}")
				print(f"mean: reduce miss count: {np.mean(miss_reduction)}")
				print(f"max: reduce miss count: {max(miss_reduction)}")
	total_result = sum([miss_reduction_distribution[r][sz] for r in miss_reduction_distribution for sz in miss_reduction_distribution[r]])
	print(f"total {total_result} experiments, max miss count reduction is {max_reduction}")
	miss_reduction_distribution_ratio = dict()
	for r in miss_reduction_distribution:
		print(f"range {r}")
		miss_reduction_distribution_ratio[r] = dict()
		for input_size in miss_reduction_distribution[r]:
			miss_reduction_distribution_ratio[r][input_size] = miss_reduction_distribution[r][input_size] / total_result
			print(f"{input_size}: \t {miss_reduction_distribution_ratio[r][input_size]} \t {miss_reduction_distribution[r][input_size]}")

