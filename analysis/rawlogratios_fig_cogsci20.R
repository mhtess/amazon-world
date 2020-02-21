df.rlr <- read_csv("~/Downloads/rawlogratios.csv")


df.rlr %>%
  gather(key, val) %>%
  mutate(above_0 = val > 0) %>%
  ggplot(., aes( x = val, alpha = above_0))+
  #geom_vline(xintercept = 0, size = 1)+
  geom_histogram(color = 'black', bins = 40)+
  scale_alpha_discrete(range = c(0.3, 0.8))+
  guides(alpha = F)+
  labs(x = "Log Likelihood Ratio", y = "Number of Responses")+
  facet_wrap(~key, scales = 'free')


ggsave("~/Desktop/rawlogratio_hists.pdf", width = 5, height = 3)
