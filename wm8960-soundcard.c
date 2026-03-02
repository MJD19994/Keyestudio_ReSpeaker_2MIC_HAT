// SPDX-License-Identifier: GPL-2.0
/*
 * ASoC Driver for WM8960 Sound Card
 *
 * Copyright (C) 2024
 * Based on simple-audio-card and existing WM8960 implementations
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>
#include <sound/soc.h>

static int wm8960_soundcard_hw_params(struct snd_pcm_substream *substream,
				      struct snd_pcm_hw_params *params)
{
	struct snd_soc_pcm_runtime *rtd = substream->private_data;
	struct snd_soc_dai *codec_dai = asoc_rtd_to_codec(rtd, 0);
	struct snd_soc_dai *cpu_dai = asoc_rtd_to_cpu(rtd, 0);
	int ret;

	/* Set codec DAI configuration */
	ret = snd_soc_dai_set_fmt(codec_dai, SND_SOC_DAIFMT_I2S |
				   SND_SOC_DAIFMT_NB_NF |
				   SND_SOC_DAIFMT_CBS_CFS);
	if (ret < 0)
		return ret;

	/* Set CPU DAI configuration */
	ret = snd_soc_dai_set_fmt(cpu_dai, SND_SOC_DAIFMT_I2S |
				   SND_SOC_DAIFMT_NB_NF |
				   SND_SOC_DAIFMT_CBS_CFS);
	if (ret < 0)
		return ret;

	return 0;
}

static struct snd_soc_ops wm8960_soundcard_ops = {
	.hw_params = wm8960_soundcard_hw_params,
};

SND_SOC_DAILINK_DEFS(wm8960,
	DAILINK_COMP_ARRAY(COMP_EMPTY()),
	DAILINK_COMP_ARRAY(COMP_CODEC(NULL, "wm8960-hifi")),
	DAILINK_COMP_ARRAY(COMP_EMPTY()));

static struct snd_soc_dai_link wm8960_soundcard_dai[] = {
	{
		.name = "WM8960",
		.stream_name = "WM8960 HiFi",
		.ops = &wm8960_soundcard_ops,
		.dai_fmt = SND_SOC_DAIFMT_I2S | SND_SOC_DAIFMT_NB_NF |
			   SND_SOC_DAIFMT_CBS_CFS,
		SND_SOC_DAILINK_REG(wm8960),
	},
};

static struct snd_soc_card wm8960_soundcard = {
	.name = "wm8960-soundcard",
	.owner = THIS_MODULE,
	.dai_link = wm8960_soundcard_dai,
	.num_links = ARRAY_SIZE(wm8960_soundcard_dai),
};

static int wm8960_soundcard_probe(struct platform_device *pdev)
{
	struct snd_soc_card *card = &wm8960_soundcard;
	struct device_node *np = pdev->dev.of_node;
	struct device_node *cpu_node, *codec_node;
	int ret;

	card->dev = &pdev->dev;

	if (!np)
		return -ENODEV;

	/* Get CPU DAI device node */
	cpu_node = of_parse_phandle(np, "i2s-controller", 0);
	if (!cpu_node) {
		dev_err(&pdev->dev, "i2s-controller missing or invalid\n");
		return -EINVAL;
	}

	wm8960_soundcard_dai[0].cpus->of_node = cpu_node;
	wm8960_soundcard_dai[0].platforms->of_node = cpu_node;

	/* Get codec device node */
	codec_node = of_parse_phandle(np, "audio-codec", 0);
	if (!codec_node) {
		dev_err(&pdev->dev, "audio-codec missing or invalid\n");
		of_node_put(cpu_node);
		return -EINVAL;
	}

	wm8960_soundcard_dai[0].codecs->of_node = codec_node;

	ret = devm_snd_soc_register_card(&pdev->dev, card);
	
	of_node_put(cpu_node);
	of_node_put(codec_node);
	
	if (ret) {
		dev_err(&pdev->dev, "Failed to register card: %d\n", ret);
		return ret;
	}

	return 0;
}

static const struct of_device_id wm8960_soundcard_of_match[] = {
	{ .compatible = "wm8960-soundcard", },
	{},
};
MODULE_DEVICE_TABLE(of, wm8960_soundcard_of_match);

static struct platform_driver wm8960_soundcard_driver = {
	.driver = {
		.name = "wm8960-soundcard",
		.of_match_table = wm8960_soundcard_of_match,
	},
	.probe = wm8960_soundcard_probe,
};

module_platform_driver(wm8960_soundcard_driver);

MODULE_AUTHOR("Seeed Technology Co., Ltd.");
MODULE_DESCRIPTION("ASoC Driver for WM8960 Sound Card");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:wm8960-soundcard");
