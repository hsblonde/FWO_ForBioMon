data {
  int<lower=0> N_long;
  int<lower=0> N_short;
  vector[N_long] time_long;
  vector[N_long] value_long;
  vector[N_short] time_short;
  vector[N_short] value_short;
}

parameters {
  real alpha_long;
  real beta_long;
  real<lower=0> sigma_long;
  real alpha_short;
  real beta_short;
  real<lower=0> sigma_short;
}

model {
  // Priors for long-term trend
  alpha_long ~ normal(0, 10);
  beta_long ~ normal(0, 10);
  sigma_long ~ cauchy(0, 2);
  
  // Long-term trend likelihood
  value_long ~ normal(alpha_long + beta_long * time_long, sigma_long);
  
  // Priors for short-term trend informed by long-term trend
  alpha_short ~ normal(alpha_long, 5);  // Informing alpha_short with alpha_long
  beta_short ~ normal(beta_long, 5);    // Informing beta_short with beta_long
  sigma_short ~ cauchy(0, 2);
  
  // Short-term trend likelihood
  value_short ~ normal(alpha_short + beta_short * time_short, sigma_short);
}
