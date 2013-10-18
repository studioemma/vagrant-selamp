<?php
if (extension_loaded('xhprof')) {
	include_once "/usr/share/php/xhprof_lib/utils/xhprof_lib.php";
	include_once "/usr/share/php/xhprof_lib/utils/xhprof_runs.php";
	function endProfilingAndSetHeader($buffer) {
		$profiler_namespace = "dev";
		$xhprof_data = xhprof_disable();
		$xhprof_runs = new XHProfRuns_Default();
		$run_id = $xhprof_runs->save_run($xhprof_data, $profiler_namespace);
		$profiler_url = sprintf('http://xhprof.dev/xhprof_html/index.php?run=%s&source=%s',
			$run_id,
			$profiler_namespace);
		header('X-Profile : ' . $profiler_url);
		$buffer = str_replace('</body>', '<a href="' . $profiler_url . '">Profiler output</a></body>', $buffer);
		return $buffer;
	}
	xhprof_enable(XHPROF_FLAGS_CPU + XHPROF_FLAGS_MEMORY);

	ob_start('endProfilingAndSetHeader');
}
